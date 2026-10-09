package com.raindrop.video;

import android.util.Log;

import java.nio.ByteBuffer;

/**
 * The Rust camera effects, as Android sees them.
 *
 * <p>The name of this class and of its one method are a contract owned by
 * RaindropCrypto, not by this plugin: the symbol the JNI linker looks for is
 * derived from them, and it is exported by {@code libraindrop_crypto_ffi.so}
 * (see that project's {@code crates/raindrop_crypto_ffi/src/jni_api.rs} and
 * {@code docs/video-effects.md}). That is why it sits in {@code
 * com.raindrop.video} rather than in this plugin's own package — the Rust side
 * knows this name and nothing else about the client.
 *
 * <p>The library is the same one the Dart bridge already loads for the
 * encryption core. Loading it again here is what registers the JNI method;
 * {@code System.loadLibrary} is idempotent, so this costs nothing.
 */
public final class NativeFrameProcessor {
    private static final String TAG = "RaindropVideo";

    private static final boolean AVAILABLE = load();

    private NativeFrameProcessor() {}

    private static boolean load() {
        try {
            System.loadLibrary("raindrop_crypto_ffi");
            return true;
        } catch (UnsatisfiedLinkError error) {
            // A build without the native library is a build without effects,
            // not a build that crashes when a camera is turned on.
            Log.w(TAG, "the Raindrop native library is not in this build, so camera effects are off", error);
            return false;
        }
    }

    /** Whether the native library is present, and so whether effects can run at all. */
    public static boolean isAvailable() {
        return AVAILABLE;
    }

    /**
     * Rewrites one I420 frame in place. Returns 0 when the frame was processed
     * and a negative number when it was left exactly as it arrived — which is
     * always a valid outcome, not an error to handle.
     *
     * <p>Each plane is passed as its buffer <em>plus</em> the offset to read
     * from, because a cropped or scaled I420 buffer is a view whose {@code
     * position()} is not zero, while JNI's {@code GetDirectBufferAddress}
     * answers for the whole region. The buffers must be direct; a heap buffer
     * is reported rather than copied.
     *
     * @param context a handle from {@code videoEffectsCreate}, or 0 for none
     */
    public static native int processI420(
            long context,
            ByteBuffer y, int yOffset, int yStride,
            ByteBuffer u, int uOffset, int uStride,
            ByteBuffer v, int vOffset, int vStride,
            int width, int height);
}
