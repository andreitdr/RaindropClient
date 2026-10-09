package com.raindrop.camera_effects;

import com.cloudwebrtc.webrtc.video.LocalVideoTrack;
import com.raindrop.video.NativeFrameProcessor;

import org.webrtc.VideoFrame;

import java.nio.ByteBuffer;

/**
 * One camera track's frames, on their way through the Rust effects.
 *
 * <p>Runs on the capture thread, inside {@code LocalVideoTrack}'s processor
 * chain. A frame that cannot be processed is passed on exactly as it arrived:
 * an unblurred frame is a cosmetic failure, a dropped one is a frozen camera.
 *
 * <p>Android cannot do what the Apple side does and mutate the frame it was
 * given, because a camera frame here is usually a GPU texture: {@code toI420()}
 * is a readback that produces a <em>new</em> buffer, so the processed frame has
 * to be a new {@code VideoFrame} wrapping it. That costs one conversion per
 * frame while effects are on, which is the price of touching pixels at all on
 * this platform.
 */
final class RaindropFrameProcessor implements LocalVideoTrack.ExternalVideoFrameProcessing {
    private final long context;

    /**
     * The buffer handed on with the previous frame, released one frame later.
     *
     * <p>{@code new VideoFrame(buffer, …)} takes over the caller's reference
     * and nothing downstream releases it, so somebody has to — and it cannot be
     * released before the sink has seen it. By the next frame the sink has
     * returned; if it needed the buffer for longer it took its own reference,
     * and reference counting makes whichever release comes last the one that
     * frees.
     *
     * <p>Volatile because {@link #dispose()} is called from the platform
     * thread, even though the chain's own lock means it can never run while
     * {@link #onFrame} is in progress.
     */
    private volatile VideoFrame.Buffer handedOn;

    RaindropFrameProcessor(long context) {
        this.context = context;
    }

    @Override
    public VideoFrame onFrame(VideoFrame frame) {
        releaseHandedOn();

        VideoFrame.I420Buffer i420 = frame.getBuffer().toI420();
        if (i420 == null) {
            return frame;
        }

        ByteBuffer y = i420.getDataY();
        ByteBuffer u = i420.getDataU();
        ByteBuffer v = i420.getDataV();

        int outcome = NativeFrameProcessor.processI420(
                context,
                y, y.position(), i420.getStrideY(),
                u, u.position(), i420.getStrideU(),
                v, v.position(), i420.getStrideV(),
                i420.getWidth(), i420.getHeight());

        if (outcome != 0) {
            // Nothing was written, so the conversion is wasted and the original
            // frame is the better one to pass on — it may still be a texture the
            // encoder can take without a readback.
            i420.release();
            return frame;
        }

        handedOn = i420;
        return new VideoFrame(i420, frame.getRotation(), frame.getTimestampNs());
    }

    /**
     * Releases the last buffer this processor handed on.
     *
     * <p>Called once the processor is out of the chain. {@code removeProcessor}
     * takes the chain's lock, which {@code onFrameCaptured} holds while it
     * iterates, so by the time this runs no frame is in flight here.
     */
    void dispose() {
        releaseHandedOn();
    }

    private void releaseHandedOn() {
        VideoFrame.Buffer buffer = handedOn;
        if (buffer != null) {
            handedOn = null;
            buffer.release();
        }
    }
}
