#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

// For the ExternalVideoProcessingDelegate protocol. Declaring conformance
// rather than relying on the method matching is what gets the compiler to
// check the signature against flutter_webrtc's own.
#import <flutter_webrtc/VideoProcessingAdapter.h>

NS_ASSUME_NONNULL_BEGIN

/// The per-frame function in Rust, reached by address.
///
/// Must match `ProcessI420` in
/// `RaindropCrypto/crates/raindrop_crypto_ffi/src/c_api.rs`. Returns 0 when the
/// frame was rewritten, and a negative number when it was left exactly as it
/// arrived — which is never an error to handle, only a reason to pass the
/// original frame on.
typedef int32_t (*RaindropProcessI420)(int64_t context,
                                       uint8_t *y,
                                       int32_t yStride,
                                       uint8_t *u,
                                       int32_t uStride,
                                       uint8_t *v,
                                       int32_t vStride,
                                       int32_t width,
                                       int32_t height);

/// Sits in a `VideoProcessingAdapter`'s chain and hands each frame's planes to
/// Rust.
///
/// Conforms to `ExternalVideoProcessingDelegate`, the protocol `flutter_webrtc`
/// declares in its public `VideoProcessingAdapter.h`.
@interface RaindropFrameProcessor : NSObject <ExternalVideoProcessingDelegate>

- (instancetype)initWithProcess:(RaindropProcessI420)process
                        context:(int64_t)context NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// The one method the chain calls, per frame, on the capture thread. Declared
/// by the protocol; repeated here only because it is the whole point of this
/// class.
- (RTCVideoFrame *)onFrame:(RTCVideoFrame *)frame;

@end

NS_ASSUME_NONNULL_END
