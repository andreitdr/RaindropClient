#import "RaindropFrameProcessor.h"

/// Copies one plane, row by row, because a camera's strides are usually wider
/// than its picture and the padding is not ours to read or write.
static void RaindropCopyPlane(uint8_t *destination,
                              int destinationStride,
                              const uint8_t *source,
                              int sourceStride,
                              int width,
                              int height) {
  if (destinationStride == sourceStride && destinationStride == width) {
    memcpy(destination, source, (size_t)width * (size_t)height);
    return;
  }

  for (int row = 0; row < height; row++) {
    memcpy(destination + (size_t)row * (size_t)destinationStride,
           source + (size_t)row * (size_t)sourceStride,
           (size_t)width);
  }
}

@implementation RaindropFrameProcessor {
  RaindropProcessI420 _process;
  int64_t _context;
}

- (instancetype)initWithProcess:(RaindropProcessI420)process context:(int64_t)context {
  if ((self = [super init])) {
    _process = process;
    _context = context;
  }
  return self;
}

- (RTCVideoFrame *)onFrame:(RTCVideoFrame *)frame {
  if (_process == NULL) {
    return frame;
  }

  id<RTCVideoFrameBuffer> buffer = frame.buffer;

  // A buffer that is already mutable I420 — one another processor produced
  // ahead of us in the chain — is rewritten where it lies, with no conversion
  // and no copy at all.
  if ([buffer conformsToProtocol:@protocol(RTCMutableI420Buffer)]) {
    id<RTCMutableI420Buffer> writable = (id<RTCMutableI420Buffer>)buffer;
    _process(_context,
             writable.mutableDataY,
             writable.strideY,
             writable.mutableDataU,
             writable.strideU,
             writable.mutableDataV,
             writable.strideV,
             writable.width,
             writable.height);

    // Either way the planes belong to this frame, so this frame is what goes
    // on: a refusal left them exactly as they arrived.
    return frame;
  }

  // A camera hands over NV12 in a CVPixelBuffer, so one conversion is
  // unavoidable. `toI420` gives an immutable buffer, hence the copy into a
  // mutable one of the same size.
  id<RTCI420Buffer> source = [buffer toI420];
  if (source == nil) {
    return frame;
  }

  // Allocated per frame rather than reused: a frame handed on may still be
  // held by the encoder, and writing the next frame into the same buffer would
  // corrupt the one in flight. `toI420` allocates anyway, so this is the cost
  // already being paid.
  RTCMutableI420Buffer *target = [[RTCMutableI420Buffer alloc] initWithWidth:source.width
                                                                      height:source.height];

  RaindropCopyPlane(target.mutableDataY, target.strideY, source.dataY, source.strideY,
                    source.width, source.height);
  RaindropCopyPlane(target.mutableDataU, target.strideU, source.dataU, source.strideU,
                    source.chromaWidth, source.chromaHeight);
  RaindropCopyPlane(target.mutableDataV, target.strideV, source.dataV, source.strideV,
                    source.chromaWidth, source.chromaHeight);

  int32_t processed = _process(_context,
                               target.mutableDataY,
                               target.strideY,
                               target.mutableDataU,
                               target.strideU,
                               target.mutableDataV,
                               target.strideV,
                               target.width,
                               target.height);

  // Refused: pass the original on untouched rather than a converted copy of
  // it. The conversion is wasted, and that is the right thing to waste.
  if (processed != 0) {
    return frame;
  }

  return [[RTCVideoFrame alloc] initWithBuffer:target
                                      rotation:frame.rotation
                                   timeStampNs:frame.timeStampNs];
}

@end
