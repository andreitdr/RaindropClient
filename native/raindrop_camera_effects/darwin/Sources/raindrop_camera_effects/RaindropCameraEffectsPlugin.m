#import "./include/raindrop_camera_effects/RaindropCameraEffectsPlugin.h"

#import <flutter_webrtc/FlutterWebRTCPlugin.h>
#import <flutter_webrtc/LocalVideoTrack.h>

#import "RaindropFrameProcessor.h"

/// The one channel name, matched in `lib/raindrop_camera_effects.dart`.
static NSString *const kChannel = @"raindrop/camera_effects";

@implementation RaindropCameraEffectsPlugin {
  /// The processor attached to each track, by track id, so `detach` can take
  /// off the same object `addProcessing:` was given — the chain is keyed by
  /// identity, not by class.
  NSMutableDictionary<NSString *, RaindropFrameProcessor *> *_attached;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
#if TARGET_OS_IPHONE
  NSObject<FlutterBinaryMessenger> *messenger = [registrar messenger];
#else
  NSObject<FlutterBinaryMessenger> *messenger = registrar.messenger;
#endif

  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:kChannel
                                                              binaryMessenger:messenger];
  RaindropCameraEffectsPlugin *instance = [[RaindropCameraEffectsPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
  if ((self = [super init])) {
    _attached = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"isSupported"]) {
    result(@YES);
    return;
  }

  if ([call.method isEqualToString:@"attach"]) {
    [self attach:call result:result];
    return;
  }

  if ([call.method isEqualToString:@"detach"]) {
    [self detach:call result:result];
    return;
  }

  result(FlutterMethodNotImplemented);
}

- (void)attach:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSString *trackId = call.arguments[@"trackId"];
  NSNumber *address = call.arguments[@"processAddress"];
  NSNumber *context = call.arguments[@"context"];

  if (![trackId isKindOfClass:[NSString class]] || address == nil || context == nil) {
    result([FlutterError errorWithCode:@"invalid_arguments"
                              message:@"attach needs a trackId, a processAddress and a context"
                              details:nil]);
    return;
  }

  LocalVideoTrack *track = [self cameraTrackWithId:trackId];
  if (track == nil) {
    result([FlutterError errorWithCode:@"track_not_found"
                              message:@"no local camera track with that id is running"
                              details:nil]);
    return;
  }

  // Idempotent: attaching twice must not leave two processors in the chain,
  // each handing the same frame to Rust.
  [self removeProcessorFrom:track forTrackId:trackId];

  RaindropProcessI420 process = (RaindropProcessI420)(uintptr_t)address.unsignedLongLongValue;
  RaindropFrameProcessor *processor =
      [[RaindropFrameProcessor alloc] initWithProcess:process context:context.longLongValue];

  [track addProcessing:processor];
  _attached[trackId] = processor;

  result(nil);
}

- (void)detach:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSString *trackId = call.arguments[@"trackId"];
  if (![trackId isKindOfClass:[NSString class]]) {
    result(nil);
    return;
  }

  // A track that has already gone is the outcome asked for, not a failure, so
  // the bookkeeping is cleared either way.
  [self removeProcessorFrom:[self cameraTrackWithId:trackId] forTrackId:trackId];
  result(nil);
}

/// The local camera track `flutter_webrtc` has under `trackId`, or nil.
///
/// `localTracks` is `flutter_webrtc`'s own public registry, keyed by exactly
/// the id Dart holds as `MediaStreamTrack.id` — which is what makes this
/// possible without passing a native object across the channel.
- (nullable LocalVideoTrack *)cameraTrackWithId:(NSString *)trackId {
  FlutterWebRTCPlugin *webrtc = [FlutterWebRTCPlugin sharedSingleton];
  id<LocalTrack> track = webrtc.localTracks[trackId];

  return [track isKindOfClass:[LocalVideoTrack class]] ? (LocalVideoTrack *)track : nil;
}

- (void)removeProcessorFrom:(nullable LocalVideoTrack *)track forTrackId:(NSString *)trackId {
  RaindropFrameProcessor *processor = _attached[trackId];
  if (processor == nil) {
    return;
  }

  [track removeProcessing:processor];
  [_attached removeObjectForKey:trackId];
}

@end
