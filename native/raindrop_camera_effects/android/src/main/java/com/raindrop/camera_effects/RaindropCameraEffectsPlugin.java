package com.raindrop.camera_effects;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin;
import com.cloudwebrtc.webrtc.LocalTrack;
import com.cloudwebrtc.webrtc.video.LocalVideoTrack;
import com.raindrop.video.NativeFrameProcessor;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Puts Raindrop's native frame processor on a camera track {@code
 * flutter_webrtc} is already capturing.
 *
 * <p>Unlike the Apple side, this does not take a function address: a Java
 * method cannot call a function pointer, so the per-frame call goes through JNI
 * into the same library, by name. The {@code processAddress} argument is
 * therefore accepted and ignored, so that Dart has one API for every platform.
 */
public class RaindropCameraEffectsPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    /** The one channel name, matched in {@code lib/raindrop_camera_effects.dart}. */
    private static final String CHANNEL = "raindrop/camera_effects";

    private @Nullable MethodChannel channel;

    /**
     * The processor on each track, by track id, so {@code detach} can take off
     * the same object {@code addProcessor} was given — the chain is keyed by
     * identity, not by class.
     */
    private final Map<String, RaindropFrameProcessor> attached = new HashMap<>();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }

        for (Map.Entry<String, RaindropFrameProcessor> entry : attached.entrySet()) {
            removeProcessor(cameraTrack(entry.getKey()), entry.getValue());
        }
        attached.clear();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "isSupported":
                result.success(NativeFrameProcessor.isAvailable());
                return;
            case "attach":
                attach(call, result);
                return;
            case "detach":
                detach(call, result);
                return;
            default:
                result.notImplemented();
        }
    }

    private void attach(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String trackId = call.argument("trackId");
        Number context = call.argument("context");

        if (trackId == null || context == null) {
            result.error("invalid_arguments", "attach needs a trackId, a processAddress and a context", null);
            return;
        }

        if (!NativeFrameProcessor.isAvailable()) {
            result.error("unavailable", "the Raindrop native library is not in this build", null);
            return;
        }

        LocalVideoTrack track = cameraTrack(trackId);
        if (track == null) {
            result.error("track_not_found", "no local camera track with that id is running", null);
            return;
        }

        // Idempotent: attaching twice must not leave two processors in the
        // chain, each handing the same frame to Rust.
        removeProcessor(track, attached.remove(trackId));

        RaindropFrameProcessor processor = new RaindropFrameProcessor(context.longValue());
        track.addProcessor(processor);
        attached.put(trackId, processor);

        result.success(null);
    }

    private void detach(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String trackId = call.argument("trackId");
        if (trackId == null) {
            result.success(null);
            return;
        }

        // A track that has already gone is the outcome asked for, not a
        // failure, so the bookkeeping is cleared either way.
        removeProcessor(cameraTrack(trackId), attached.remove(trackId));
        result.success(null);
    }

    /**
     * The local camera track {@code flutter_webrtc} has under {@code trackId},
     * or null.
     *
     * <p>{@code getLocalTrack} is {@code flutter_webrtc}'s own public registry,
     * keyed by exactly the id Dart holds as {@code MediaStreamTrack.id} — which
     * is what makes this possible without passing a native object across the
     * channel.
     */
    private @Nullable LocalVideoTrack cameraTrack(@NonNull String trackId) {
        FlutterWebRTCPlugin webrtc = FlutterWebRTCPlugin.sharedSingleton;
        if (webrtc == null) {
            return null;
        }

        LocalTrack track = webrtc.getLocalTrack(trackId);
        return track instanceof LocalVideoTrack ? (LocalVideoTrack) track : null;
    }

    private void removeProcessor(@Nullable LocalVideoTrack track, @Nullable RaindropFrameProcessor processor) {
        if (processor == null) {
            return;
        }

        if (track != null) {
            track.removeProcessor(processor);
        }

        // After removeProcessor the chain's lock guarantees no frame is in
        // flight, so the buffer it was still holding can go.
        processor.dispose();
    }
}
