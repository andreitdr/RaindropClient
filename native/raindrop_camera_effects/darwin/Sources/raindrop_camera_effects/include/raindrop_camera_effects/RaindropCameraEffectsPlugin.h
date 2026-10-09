#if TARGET_OS_IPHONE
#import <Flutter/Flutter.h>
#elif TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/// Puts Raindrop's camera effects into the capture pipeline of a camera track
/// `flutter_webrtc` is already running.
///
/// Nothing is forked or patched. `flutter_webrtc` already exposes everything
/// needed, publicly — it just does not use it from its own Dart layer:
/// `+[FlutterWebRTCPlugin sharedSingleton]` to reach the plugin, its
/// `localTracks` property to find a track by the id Dart already holds, and
/// `-[LocalVideoTrack addProcessing:]` to put a delegate in the chain every
/// captured frame already flows through.
///
/// This plugin holds no Raindrop symbol and links against nothing of ours: it
/// is handed a function **address** and an opaque context, both plain integers
/// that came from Rust by way of Dart, and would work the same against any
/// other processor.
@interface RaindropCameraEffectsPlugin : NSObject <FlutterPlugin>
@end

NS_ASSUME_NONNULL_END
