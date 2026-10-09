# raindrop_camera_effects

Attaches a native per-frame processor to a camera track `flutter_webrtc` is
already capturing.

## Why this plugin exists

Raindrop's camera effects run in Rust (`../../../RaindropCrypto/crates/raindrop_video`).
To reach a camera frame at all, something native has to sit in the capture
pipeline — the Flutter media library exposes no way to touch a frame from Dart.

**`flutter_webrtc` already has that seam, and already makes it public.** It
simply does not use it from its own Dart layer:

| | iOS / macOS | Android |
|---|---|---|
| Plugin instance | `+[FlutterWebRTCPlugin sharedSingleton]` (public header) | `public static FlutterWebRTCPlugin sharedSingleton` |
| Track by id | `.localTracks`, a public property (`trackId → id<LocalTrack>`) | `public LocalTrack getLocalTrack(String trackId)` |
| Frame hook | `-[LocalVideoTrack addProcessing:]` with the `ExternalVideoProcessingDelegate` protocol — both public pod headers | `LocalVideoTrack.addProcessor(ExternalVideoFrameProcessing)`, and every captured frame already flows through it |

So this plugin walks in the front door. **Nothing is forked and nothing is
patched** — no `dependency_overrides`, no sha pin, no rebasing onto upstream.

## What it does

Two calls. `attach` looks the track up by the id Dart already holds, wraps it in
a processor, and hands that processor a **function address** plus an opaque
context — both plain integers that came from Rust by way of Dart. `detach`
removes it.

On Apple the plugin therefore links against nothing of Raindrop's and holds no
Raindrop symbol: it moves pixels to an address it is told about, and would work
just as well against any other processor.

## The Android difference

**A Java method cannot call a function pointer.** So on Android the per-frame
call goes through JNI into the same Rust library, bound by name:
`com.raindrop.video.NativeFrameProcessor.processI420`, declared here and
exported by `libraindrop_crypto_ffi.so` — the library the Dart bridge already
loads for the encryption core, which is why there is no CMake block, no NDK
toolchain of this plugin's own and no second `.so`. The class sits in
`com.raindrop.video` because **that name is RaindropCrypto's contract**, not
this plugin's; see its `docs/video-effects.md`. `processAddress` is still
accepted and ignored, so Dart has one API for every platform.

Two more things differ, and both come from how Android delivers frames:

- **A camera frame here is usually a GPU texture**, so `toI420()` is a readback
  that produces a *new* buffer — the frame cannot be rewritten where it lies the
  way it can on Apple, and the processed frame has to be a new `VideoFrame`.
- **Somebody has to release that buffer.** `new VideoFrame(buffer, …)` takes
  over the caller's reference and nothing downstream releases it, and it cannot
  be released before the sink has seen it. So it is released one frame later:
  by then the sink has returned, and if it needed the buffer for longer it took
  its own reference, which makes whichever release comes last the one that
  frees.

## What it depends on

flutter_webrtc's **public** API: the three rows in the table above. A version
bump needs those three checked, which is a far smaller surface than a patch
would be. `docs/voice.md` in the client records the same thing.

Nothing of flutter_webrtc ships inside this plugin. On Apple it is an SPM
package depending on flutter_webrtc's own `flutter-webrtc` and `WebRTC`
products, the same cross-plugin dependency `livekit_client` already declares.
On Android it is `compileOnly project(':flutter_webrtc')` plus `compileOnly` on
the WebRTC AAR, because both are already in the app and a second copy of the AAR
would be tens of megabytes of duplicate classes.

## Platforms

iOS, macOS and Android. Windows and Linux report unsupported: there
`flutter_webrtc`'s C++ keeps its track registry `protected` and has no
processing chain between capturer and source at all, so they need a different
approach. The camera itself works on every platform regardless — only the
effects are gated, by `canUseCameraEffects`.
