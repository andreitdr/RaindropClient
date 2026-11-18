# Voice

Voice channels are group calls. You join one and everybody in it hears everybody else. You can
**mute** your microphone, **deafen** yourself (you stop hearing anyone, which also mutes you), turn
any member **up or down** or **mute them just for you**, and, with the `mute_members` permission,
**mute them for everyone**. The server side is in the server's
[Voice doc](../../RaindropServer/docs/voice.md). This file covers what the client does.

## How a call is carried

The server decides who may join, speak and moderate. The audio travels over a **media transport**
the server names when you join (`VoiceJoinResult.transport`), which today is `livekit`. The code is
split the same way:

- `core/voice/voice_engine.dart` defines `VoiceEngine`, which is everything the app needs from a
  call's audio: connect, microphone on/off, per-member volume, a default volume, devices, audio
  processing, and streams for connection state, active speakers, disconnects and permission changes.
  `createVoiceEngine(transport)` picks the implementation by name, and returns null for a transport
  this build does not speak, so a server added later with a different transport fails with a clear
  message instead of a crash.
- `core/voice/livekit_voice_engine.dart` is the LiveKit implementation. It is the **only** file that
  imports `livekit_client` or `flutter_webrtc`. It sends speech-bitrate Opus with DTX (silence is sent
  as nothing). **Adaptive stream and dynacast are on**: video goes only where a tile is visible, at
  the size it is drawn, and a layer nobody receives is not even encoded — which is what makes an
  unwatched screen share cost its sharer nothing. One consequence is load-bearing: with adaptive
  stream, `publication.enabled` turns false whenever no tile is visible, so the feed list filters on
  this client's own wishes (a hidden camera, a watched share) and never on `enabled` — a feed dropped
  for being invisible would never get a tile to become visible in.

**The connection goes through the server you already pin.** Joining, leaving, mute and deafen are
gRPC calls (`VoiceService`), and call state arrives on the event stream. The audio's signalling is the
one connection to the server that is not gRPC: LiveKit's own WebSocket, which its SDK opens and the
server relays.

The join response has `path: /api/channels/voice/signal` and no `url`, so `VoiceJoinResult.signalUri`
builds `wss://<host>:<port>/api/channels/voice/signal` from the server profile. LiveKit's SDK opens
`/rtc` under it, and the server relays that to LiveKit. The server's self-signed certificate therefore
has to be trusted by LiveKit's own sockets, which `RaindropChannel`'s pinning does not reach. Two
things handle it:

- **`PinRegistry`** (`core/network/pin_registry.dart`) holds the pinned fingerprint of every server
  with a session. `ServerSessionController` registers it on cold start and on `adopt` after a first
  connection.
- **`PinnedHttpOverrides`**, installed as `HttpOverrides.global` in `main.dart`, gives every
  `HttpClient` in the process a `badCertificateCallback` that accepts exactly those fingerprints and
  nothing else. It only runs when the platform's own check fails, the same way `CertificatePinner`
  does.

LiveKit's own `CertificatePinningOptions` is deliberately not used. It checks the chain and hostname
before it looks at any pin, and a self-signed certificate reached by an address it does not name
never passes.

The audio itself is DTLS-SRTP to the LiveKit server, over UDP 7882 or the TCP 7881 fallback, and
**end-to-end encrypted inside that** on a server that offers it (`e2ee.voice.v1`).

## End-to-end encrypted calls

(Server side: [Voice](../../RaindropServer/docs/voice.md#end-to-end-encrypted-calls).)

- **The key.** Before joining, `VoiceCallController.join` gets the call's media key from the voice
  channel's MLS group: `ChannelGroups.mediaKey`, which joins the group if needed and exports
  `raindrop/voice/v1` for the current epoch into slot `epoch mod 16`. It fetches the key **before**
  telling the server it is joining. If it cannot get a key on a server that requires one, it refuses
  with `VoiceEncryptionUnavailableException` (shown as a snack bar) and never joins in the clear.
- **The engine.** `LiveKitVoiceEngine.connect(mediaKey:)` hands LiveKit a shared-key `BaseKeyProvider`:
  - key ring 16
  - ratchet window 0: keys are never derived from old ones
  - failure tolerance −1: failures never switch encryption off

  It passes that provider as `RoomOptions.encryption`, and moves senders onto the key's slot.

  The provider is `_SharedKeyProvider`, a subclass that **remembers the shared key's slot**. LiveKit
  starts every frame cryptor (one per track, created when the track is published) on
  `getLatestIndex`. In shared-key mode, the stock `BaseKeyProvider` never records the slot
  `setSharedKey` was given, so it always answers 0. `E2EEManager.setKeyIndex` only reaches cryptors
  that already exist. As a result, a camera or screen share started after joining was encrypting
  with an empty slot: `kMissingKey`, every frame dropped, zero bytes sent. LiveKit announces a
  track only once its media arrives, so nobody else ever saw it, while the sender's own preview
  looked fine. Symptom to recognise: the sender's `TrackE2EEStateEvent` reads `kMissingKey` and its
  sender stats show frames encoded but `bytesSent` 0. Re-check this on any `livekit_client` bump.
- **Key changes.** `ChannelGroups.epochChanges` fires whenever the group's epoch moves. The controller
  then exports the new key and calls `engine.setMediaKey`, which sets the key and switches this
  participant's senders to its slot; receivers keep the older slots for frames in flight. The key is
  also refreshed once right after connecting, in case the epoch moved during connect.
- **Rotation.** Every 10 minutes, the participant with the lowest member id rotates the group's keys
  (`ChannelGroups.rotate`), so a call rekeys once per interval rather than once per participant.
- **Failing closed.** A remote track published without encryption marks that *participant* untrusted
  for as long as they are in the call: their audio is kept at volume 0 and their camera is never
  drawn, whatever the keys do afterwards. A client that sent one frame in the clear is not using the
  group's key, and republishing does not earn it a second chance. A *publication* whose frames stop
  decrypting is silenced until a key change or a good frame — that verdict is per track sid, because
  LiveKit keeps one frame cryptor per track, so one participant's microphone can decrypt while their
  camera does not and neither verdict may reach the other.
  `engine.encryptionChanges` reports `active`, `degraded` or `none`.
- **Warnings.** `engine.warnings` is how the engine says it refused something without ending the
  call — media it could not encrypt, an effect it had to turn off. It becomes
  `VoiceCallState.warning`, shown as a dismissible banner in the voice view. Deliberately not
  `VoiceCallState.notice`, which means specifically why a call *ended*; a warning leaves the call
  running, and conflating the two would read as a hang-up that did not happen.
- **The lock.** `VoiceCallState.encryption` drives a lock in `VoiceConnectionBar`:
  - a closed lock: encrypted
  - a clock-lock: somebody is not decrypting and is silenced
  - an open lock: the server does not offer encrypted calls, so its media server can hear

### Codecs and the frame cryptor

The call states its video codec (`RoomOptions.defaultVideoPublishOptions`) instead of inheriting the
SDK's default, because here the codec is a security setting and not only a quality one. VP8, with
simulcast and the backup codec pinned to it as well, so no negotiation can quietly land elsewhere.

**AV1 is refused outright** (`blockedVideoCodecs` in `core/voice/voice_engine.dart`). `livekit_client`
skips frame-cryptor setup entirely for AV1 — the `isAV1Codec` early returns in `e2ee_manager.dart`,
in both the publish and the subscribe handler — while the publication still reports its encryption
type as AES-GCM. An AV1 track would therefore travel **in the clear with nothing to notice it**, and
a check on the publication's own encryption state cannot catch it. So:

- **Sending**, `LocalTrackPublishedEvent` withdraws any video publication whose codec is blocked or
  whose encryption never came up, and warns the user that the camera was turned off. This is the one
  thing standing between a camera and the media server seeing it; the receive side can only keep
  somebody else's mistake quiet.
- **Receiving**, a blocked codec counts as unencrypted even when the publication claims otherwise.
  Audio is kept silent (silence is the guarantee, and dropping the subscription would lose the
  speaking indicator with it); video is unsubscribed, since it will never be drawn and so should not
  cost bandwidth either.

A `livekit_client` bump must re-read those two early returns before anything is removed from
`blockedVideoCodecs`. `test/features/voice/voice_trust_test.dart` guards the list and the two pure
rules (`gatedVolume`, `isBlockedVideoCodec`).

### Checking it by hand

The integration test (`test/integration/e2ee_voice_test.dart`) covers the keys, including that every
member derives the same one, rotation, and removal. It cannot play audio. To check the audio path:

1. Put two devices in a call and confirm both show the closed lock and hear each other.
2. Join the same LiveKit room from outside Raindrop with a token minted by the server's LiveKit key
   (for example with the LiveKit CLI, `lk room join`). That participant receives only undecodable
   frames: noise or silence, never speech.
3. To prove the codec guard rather than trust it, force `_videoCodec` to `'av1'` in a scratch build
   and turn a camera on: the publication must be withdrawn and the warning banner must appear, with
   nothing sent. Worth doing once, deliberately, since nothing else exercises that path.

## Camera

Available when the server advertises `voice.video.v1`; the camera button is hidden
rather than offered and refused when it does not. Encryption is the same key and
the same guarantee as the voice — see above.

### Showing your camera

Turning the camera on opens the **camera-and-effects sheet** first
(`camera_effects_sheet.dart`, also reachable from Settings → Voice & video →
Camera & effects): a live preview, the camera picker, the quality, and the
background effect. Nothing is published while it is open — the preview is a
camera of its own, so the sheet works with no call in progress at all, and the
preview *is* the confirmation: every change is applied to it immediately.

Joining a call is still one tap. The sheet opens on the camera, not on the join,
so nobody listening to a call is made to walk past a device check first.
The choice is remembered in `voiceSettingsProvider`, so after the first time
turning the camera on is one tap and the sheet.

**The handshake, which is the one piece of real sequencing.** A call token names
the microphone only, whatever the member's permissions say; the server adds the
camera once this client says its camera is on. So `VoiceCallController.setCameraEnabled`:

1. tells the server (`setSelfState(cameraOn: true)`), which is where the `video`
   permission and the per-call camera cap are checked;
2. waits up to five seconds for the media server to hand the grant over, which
   arrives as `VoiceEngine.publishRights` — a grant already in place returns at
   once;
3. publishes.

If the grant does not come, it **takes the claim back**, rather than leaving a
camera the server thinks is on and nobody can see. Turning the camera off is the
reverse order — stop publishing, *then* tell the server — so the grant is never
withdrawn from under a live track.

**Publishing is single-flight.** The grant arriving wakes two parties at once:
the engine's `ParticipantPermissionsUpdatedEvent` handler and the controller
waiting on `publishRights`. Two overlapping `setCameraEnabled(true)` calls can
leave this device showing a camera track that nobody else receives. So
`LiveKitVoiceEngine._applyCamera` joins a publish already in flight instead of
starting a second one. The handler also publishes only a camera that was wanted
*before* it announced the new rights (a reconnect, or a grant given back), and
leaves a fresh turn-on to the controller.

**Receiving it.** A remote camera becomes a feed once it is subscribed. A
`TrackSubscriptionExceptionEvent` is retried once with `subscribe()`, then shown
as a warning, so it is never silently dropped. Every event that can make a
missed feed appear later (subscription permission, stream state, mute/unmute)
rebuilds the feed list. A camera publication that arrives unsubscribed (not
hidden, not untrusted) is subscribed explicitly as a backstop for auto-subscribe.

`VoiceCallState.cameraBusy` covers that round trip: the button shows a spinner
and refuses a second tap, and the state it owns is not overwritten by the
`voice.state` event or the engine's own `cameraStates` while it is in flight.

**Mid-call changes.** Swapping the effect is free — it is a processor on the
frames, not a property of the capture. Changing the camera or the quality
restarts the track, which other participants see as a brief freeze;
`VoiceCameraOptions.needsRestartFor` is what tells the two apart.

**Backgrounding** turns the camera off on iOS and Android, where the OS stops it
anyway and everybody else would be left looking at a frozen frame. Desktop is
left alone: a hidden window is still a live camera there, and stopping it
silently would surprise.

### Camera effects

Background blur and background replacement, applied to the camera's frames
**in place** before they reach the encoder. Offered in the sheet before the
camera goes on, and switchable while it is on — swapping the effect changes a
processor on the frames, not a property of the capture, so nothing restarts and
nobody sees a freeze.

The work is Rust, in
[RaindropCrypto's camera-effects core](../../RaindropCrypto/docs/video-effects.md).
**No frame comes through Dart** — the media library exposes no way to touch one.
What Dart does is open an effects handle, ask for the address of the C function
that processes a frame, and hand both to the platform's capture pipeline:

```
camera_effects_sheet / voice settings
        │  VoiceCameraEffect (kind, strength, background path)
        ▼
core/video/camera_effects_engine.dart ── CameraEffects.start()
        │                                 (the only file outside core/crypto/
        │                                  that imports the generated bridge)
        │  handle + process address, both plain integers
        ▼
core/voice/livekit_voice_engine.dart ── _TrackEffects
        │  RaindropCameraEffects.attach(trackId:, processAddress:, context:)
        ▼
native/raindrop_camera_effects  ──►  flutter_webrtc's own processor chain
        │                            (addProcessing: / addProcessor)
        ▼
    per frame, on the capture thread, into Rust
```

**Nothing is forked and nothing is patched.** `flutter_webrtc`'s per-frame hook
is already public on both Apple (`LocalVideoTrack addProcessing:`,
`ExternalVideoProcessingDelegate`) and Android
(`LocalVideoTrack.addProcessor`, `ExternalVideoFrameProcessing`) — it is only
its *Dart* layer that never uses it. So `native/raindrop_camera_effects` is a
small plugin of our own that reaches those APIs and nothing else; it looks the
track up in `flutter_webrtc`'s own public registry by the id Dart already holds
as `MediaStreamTrack.id`. On Apple it resolves to SPM, which is how
`livekit_client` already depends on `flutter_webrtc`'s `WebRTC` product.

Android is the one platform that cannot be handed a function address — a Java
method cannot call a function pointer — so the per-frame call goes through JNI
into the same Rust library, by name. That is also why Android has to convert the
frame (`toI420()` is a GPU readback there) and hand on a new `VideoFrame`, where
Apple can rewrite the buffer it was given.

**Two things the UI asks rather than assumes.** `canUseCameraEffects`
(`platform_info.dart`) is the platform half: is there anywhere to put a
processor. `cameraEffectsAvailable` (`camera_effects_engine.dart`) is the whole
answer, and it includes whether the build carries a segmentation model — a build
without one offers no effect at all, because blurring the wrong shape is worse
than a plain camera. One **is** committed (MediaPipe Selfie Segmentation,
Apache-2.0, in `raindrop_video/models/`), so effects are on by default wherever
the platform can take a processor; a checkout of RaindropCrypto without that
file still builds, and the sheet then says so rather than offering an effect
that would blur an oval.

**The picture for a replaced background is the user's own file**, chosen with
the same `file_selector` dialog the layout import uses, and only its *path* is
kept — in voice settings, and across the bridge. The native side opens and
decodes the file itself, so a 4K photograph never becomes 24 MB of Dart list.
The dialog offers exactly the formats `raindrop_video` compiles the `image`
crate with (JPEG, PNG, WebP), so a file that gets through it is one that can
actually be used; a file that has since moved or cannot be decoded fails the way
every other effect failure does, as a warning with the camera still running.
Choosing "Picture" when none has been chosen opens the dialog straight away,
because otherwise it would change nothing visible.

Two things the sheet does that are easy to miss:

- **It waits for the first mask.** Segmentation runs well below the frame rate
  and starts cold, so the first frames go through untouched. Showing them reads
  as the effect having failed rather than as not having started, so the preview
  stays behind its indicator until `CameraEffectsLoad.warm`, for up to two
  seconds.
- **It says when something was given up.** The degradation ladder lives in Rust,
  not in the UI; the sheet reads `degraded` and says so once.

An effect that cannot be applied is never fatal. `_TrackEffects.apply` returns a
warning instead of throwing, the camera carries on without it, and the engine
puts the warning on `warnings` — a camera without its blur is a cosmetic
failure, and a dropped camera is not.

### Hiding somebody's camera

The member menu's **Hide camera** ("Only for you — they are not told") is local
and real: the engine calls `disable()` on that publication, which tells the
media server to stop forwarding the track *to this subscriber*. So it saves the
bandwidth as well as the screen space, while the subscription and its frame
cryptor stay set up — which is what makes showing it again immediate rather than
a renegotiation. `unsubscribe()` is kept for the untrusted case, where a track
must never come back.

The sharer is unaffected and never told; everybody else still sees them.

It is a **standing wish about a person**, not about a publication: the engine
remembers it and re-applies it on `TrackPublishedEvent`, so somebody who turns
their camera off and on again, or who rejoins, does not come back visible. It is
persisted beside per-member volume (`memberAudioProvider`, `MemberMedia`), so it
survives a restart.

A hidden camera shows `VoiceVideoPlaceholder` with a **Show** button, and
`VoiceStatusIcons` carries a `videocam_off` marker. An *untrusted* camera gets
the same box with a different reason and no way to show it — nothing untrusted is
ever drawn.

### Camera video on the wire

The server carries camera video when it advertises `voice.video.v1`
([server docs](../../RaindropServer/docs/voice.md#camera-video)). What the protocol adds:

- `VoiceParticipant.cameraOn` / `.cameraSuppressed` — on every `voice.state` event and in every
  roster, merged on `(channelId, userId)` like the rest of the state. `cameraSuppressed` means they
  lack `video` or every camera place in the call is taken.
- `VoiceStatus.maximumCameraPublishers` — how many cameras one call carries at once; 0 when this
  server carries none.
- `VoiceParticipant.screenShareOn` / `.screenShareKind` (`VoiceShareKinds.screen` or `.window`) /
  `.screenShareAudio` / `.screenShareSuppressed` and `VoiceStatus.maximumScreenShares` — the same for
  screen sharing (`voice.screen.v1`); see [Screen sharing](#screen-sharing).
- `VoiceStatus.maximumScreenShareHeight` / `.maximumScreenShareFrameRate` — the best the server's owner
  lets a share be sent at (0 for either: none stated, as from an older server). They become
  `VoiceRoster.shareLimit`; see [How good a share is](#how-good-a-share-is).
- `VoiceApi.setSelfState(cameraOn:, screenShareOn:, …)` — **the whole self-state, not a change.**
  The server reads every field, so a mute that left out the camera would turn the camera off at the
  server and withdraw its grant from under the live track. `cameraOn` and `screenShareOn` are
  therefore required parameters, and every report goes through
  `VoiceCallController._sendSelfState`, which repeats the camera and the share as last *claimed* to
  the server (`_cameraClaimed`, `_shareClaim`) — not `VoiceCallState.cameraOn`, which only turns
  true once the track is sending, after the server has already been told. A claim the server
  refuses is put back, so the next mute does not ask for it again.
- **The camera is a piece of self-state that can be refused.** Mute and deafen are only everybody's
  icons; turning the camera on is what earns the media server's permission to send one, so it
  answers `missing_permission` without `video` and `camera_limit_reached` when the call is full of
  cameras. A refusal leaves a mute in the same request standing, so the two have to be reported
  separately.

The camera grant follows the camera being on, not the permission: a join token names the microphone
only, and the server adds the camera after `setSelfState` succeeds. So a client **waits for the
permission update before publishing**, and stops publishing *before* turning the camera off on the
server — never the other way round, or the grant would be withdrawn from under a live track.

## Screen sharing

The server carries screen sharing when it advertises `voice.screen.v1`
([server docs](../../RaindropServer/docs/voice.md#screen-sharing)). A member shares **a whole screen**
or **one window**; a window can also carry **its own sound**, if its sharer ticks the box every time
they share. A screen is never shared with sound — the host's sound is never sent — and that is held
in three places: `VoiceScreenShareOptions` drops `withAudio` for a screen before anything sees it,
the engine asks the capturer for sound only for a window, and the server never grants a screen's
sound anyway.

**Who can share.** Every platform Raindrop runs on (`canShareScreen`). The desktops choose a screen
or a window. A phone or a tablet shares **everything on its screen** and nothing less
(`sharesWholeDeviceOnly`), because that is all either system offers; see [On a phone](#on-a-phone).

**Whose sound can be shared** — `windowAudioUnavailableReason(windowId)` in `platform_info.dart`:

| Platform | A window's sound |
|---|---|
| Windows 11 (build 20348+) | Yes. flutter_webrtc already captures it with WASAPI *process-tree* loopback into a separate track, published as `screenShareAudio` |
| Windows 10 | No: its audio engine cannot separate one app's sound from everything else's |
| macOS | Not yet. Apple's WebRTC build has no custom audio source, so the only way without a fork is mixing it into the microphone track — decided against |
| Linux | Not yet. flutter_webrtc's capture records the whole default output, Raindrop's own call included, and ignores which window was chosen; it needs a change in flutter_webrtc itself |
| Android, iOS | Never: a phone shares its whole screen, and a whole screen is shared without sound |

**The process-tree guard (Windows).** The capture takes the window's process *and everything it
started*. That is right for a browser, whose sound comes from a child process, and badly wrong for
Explorer, which started nearly everything — Raindrop included. So sound is refused for Raindrop's own
windows and for any window whose process is one of Raindrop's ancestors
(`windowAudioRefusal`, answered by `core/platform/windows_processes.dart` over `dart:ffi`: the
window's owner, and a Toolhelp32 walk up from this process). A UWP app's window belongs to
`ApplicationFrameHost`, whose tree does not contain the app, so it shares silently. And if the window
has closed by the time sharing starts, flutter_webrtc falls back to *all* sound except Raindrop's —
so the window is checked again (`isWindowStillOpen`) right before sharing.

### How good a share is

A sharer chooses **Auto**, or a **maximum**: 480p, 720p or 1080p, at 15, 24, 30 or 60 frames a second
(`VoiceShareQuality`, remembered in `VoiceSettings.shareQuality`). Both are ceilings, never promises.
Auto's ceiling is **1080p at 30** (`autoShareResolution`, `autoShareFrameRate`) — 60 is something a
sharer asks for, since it costs half as much again in upload and a great deal of processor for what
is, most of the time, a document.

**What makes it automatic is that a share is sent in three versions at once** (`shareLadder`, VP8
simulcast). Nothing in the app measures a connection or decides anything:

| Ceiling | Smallest | Middle | Top |
|---|---|---|---|
| 1080p | 360p @ 15, 0.4 Mbit/s | 720p @ ≤30, 1.5 Mbit/s | 1080p @ chosen rate |
| 720p | 240p @ 15, 0.2 Mbit/s | 480p @ ≤30, 0.8 Mbit/s | 720p @ chosen rate |
| 480p | 240p @ 15, 0.2 Mbit/s | 360p @ ≤30, 0.4 Mbit/s | 480p @ chosen rate |

- **Each viewer is sent the largest version their own connection carries**, chosen by the media
  server and changed as that connection changes — so one viewer on a train does not cost anybody else
  their picture, which a single version cut down to suit the weakest viewer would. It also picks by
  the size the share is drawn at (adaptive stream), so a share in a small strip is not sent at 1080p.
- **The sharer's own connection is handled from the other end.** Versions are filled smallest first,
  so an upload that cannot afford the top simply does not send it, and a version nobody is receiving
  is not encoded at all (dynacast).

The top version's ceiling, in kbit/s (`shareTopBitrate`) — a screen that is not changing costs a
small fraction of it:

| | 15 | 24 | 30 | 60 |
|---|---|---|---|---|
| 480p | 500 | 700 | 800 | 1200 |
| 720p | 1200 | 1600 | 2000 | 3000 |
| 1080p | 2500 | 3200 | 4000 | 6000 |

**Always three versions, whatever the ceiling**, and that is load-bearing: the number is fixed when a
share is published. A ladder two long at 720p and three at 1080p could not be moved between them
without stopping the share — and on a phone, stopping means asking the system for consent again.
Three everywhere is what lets `setScreenShareQuality` change a running share's ceiling with nothing
unpublished and nothing captured again. One exception: a desktop capture delivers frames at the rate
it was opened with, so *raising* the frame rate above that reopens the capture (same source, nobody
asked anything; a brief freeze).

**What it gives up first** (`shareKeepsResolution`): at 15 frames a share is a document, and text that
goes soft is unreadable while text that updates late is not, so it keeps its resolution and drops
frames (`maintainResolution`). Anything faster was chosen for motion, and Auto has to serve both, so
those give up a little of each (`balanced`).

**Three ceilings apply, the lowest of each half winning** (`shareLimitFor`, applied in
`VoiceCallController.startScreenShare` so no caller can forget it). Widgets read it as
`voiceShareLimitProvider`; the controller works the same answer out itself (`_shareLimit`), because
that provider watches the call and the call reading it back is a circular dependency Riverpod
refuses:

1. the sharer's own choice;
2. the server owner's (`voice.maximumScreenShareHeight` / `maximumScreenShareFrameRate`, arriving as
   `VoiceRoster.shareLimit`). **Honoured here, not enforced there**: the media is end-to-end encrypted
   and the server never sees a frame, so there is nothing for it to measure — the same kind of promise
   the 1080p box always was;
3. the platform's (`maximumShareFrameRate`): iOS is held to 30, see below.

The picker lists what a ceiling rules out, greyed, and says whose ceiling it is
(`shareLimitExplanation`).

**The cap is enforced on the sender, by us.** livekit_client cannot: on desktop it works out a share's
encodings from the size it *asked* for, not the size it got (`getSettings()` is read on web and
mobile only), and the desktop capturers ignore size constraints, so left alone a 4K screen goes out at
4K. On a phone it does read the real size and scales the lower versions from it — which, multiplied by
a correction of ours, would scale them twice. So `_ShareSendGuard` **owns every encoder's settings
outright**: it reads the size actually being captured from the sender's `media-source` statistic (the
largest encoded layer, scaled back up, if that is missing) and sets each encoder's
`scaleResolutionDownBy`, `maxFramerate` and `maxBitrate` from its version of the ladder
(`shareLayerScales`) — the picture fitted inside that version's box, turned for a portrait source,
never scaled up. It looks every 250 ms until it has a size and every 2 s after, since windows are
resized and a phone is turned on its side. For the first quarter-second a share can go out unscaled;
the top version's bitrate bounds the bandwidth even then.

Two details in that:

- **A small source is still sent in three sizes.** A 900×600 window already fits the 720p box as well
  as the 1080p one, and would be sent twice at the same size. So each version is also at least 1.5×
  smaller than the one above it (`shareLayerStep`).
- **The capture is always opened asking for 1920×1080**, whatever the ceiling. No capturer honours the
  size, and LiveKit opens a third encoder only for a source it believes is at least 960 across — which
  a 480p box would not be.

**What the sharer is told** (`voiceShareSendStatsProvider`, shown in `VoiceOwnShareBar`). The same 2 s
look reads what is really going out — the largest version being sent, its frame rate, the bits all
versions cost together — and, when that is less than the ceiling, why
(`VoiceShareLimitedBy`): the encoder's own `qualityLimitationReason` (`bandwidth` → *your
connection*, `cpu` → *this device*), or the top version being switched off by the media server because
**nobody is watching it any larger**, which is no fault at all and is said so nobody goes looking for
one. For the first 8 seconds nothing is blamed on the connection: every share starts on its smallest
version and works up as the connection is measured, which the encoder also reports as a bandwidth
limit. With no viewers nothing is encoded, and the bar says that too. It is its own provider rather than
a field of the call state, because it changes every two seconds and nearly everything on screen
watches the call state.

**How a share is sent** (`_screenPublishFor`): VP8 pinned for both codecs (the codec is a security
setting, see [Codecs](#codecs-and-the-frame-cryptor)), the three versions named outright rather than
left to LiveKit's default of one half-size layer, and the degradation rule above. A window's sound
goes as music (`presetMusic`, no DTX), not with the microphone's speech settings, which would cut a
film's quiet passages to nothing.

**1080p at 60 is software VP8 on most machines**, and expensive. Nothing refuses it: WebRTC throttles
a device that cannot keep up, and the readout says *limited by this device*. A hardware codec (H.264)
would be far cheaper but is not a free choice here — see [Codecs](#codecs-and-the-frame-cryptor).

### On a phone

A phone or a tablet shares its whole screen — other apps, the home screen, notifications. Neither
system lets an app capture one other app, so there is no picker: `showScreenSharePicker` shows a sheet
that says what will be seen and offers the quality, and the source is always `deviceScreenSource`,
shared as a *screen* (so never with sound, and with no change to the protocol).

**The system's consent comes first** (`VoiceEngine.prepareScreenCapture`), before the server is told
anything — so somebody who backs out at the system's sheet was never announced as sharing. Whatever it
obtained is handed back if the share then does not start (`cancelScreenCapture`). The order is:

1. `prepareScreenCapture` — the system's own sheet;
2. the server claim, and the wait for the media server's grant (the camera's handshake, below);
3. `CallSessionHost.setScreenCapture(true)`;
4. capture and publish.

**Android** captures through MediaProjection, by way of flutter_webrtc.

- Consent is `Helper.requestCapturePermission()`: Android's "share your screen with Raindrop?" sheet.
  Since Android 14 an answer is good for **one capture**, so it is asked before every share and never
  remembered. That sheet is also where recent Android offers **one app** instead of the whole screen;
  the choice is the system's and the app is not told which was made, so the share is announced as a
  screen either way and Raindrop's own sheet says both are possible.
- Android only hands over the screen to an app with a foreground service of type `mediaProjection`
  running, and from Android 14 only lets a service *take* that type once the user has agreed. So the
  call's own service (`CallForegroundService`) adds the type after the consent and before the capture
  and drops it when the share ends — it is not held for the whole call. That is step 3, and it answers
  whether the service took the type, because a capture started without it is refused by the system.
- The call's notification says **Sharing your screen** and gains **Stop sharing**, since the whole
  point of sharing is being in some other app. It is only visible if notifications are allowed, which
  `MainActivity` asks for the first time a call begins (see [Android and iOS](mobile.md#permissions)).
- **A capture the system ended** — its own stop control in the status bar, or (Android 14+) the screen
  locking — is reported by nobody: flutter_webrtc's `MediaProjection.Callback.onStop` does nothing,
  and a track that stops receiving frames looks exactly like a screen that is not changing. What does
  change is the virtual display the capture draws into (`WebRTC_ScreenCapture`): switched off when the
  projection stops, gone when it is released. The service watches that display and, after 1.5 s without
  a live one (turning the phone replaces it, so a moment without one is a rotation), tells Dart —
  `CallSessionHost.screenCaptureEnded`, which the notification's Stop sharing uses too. The controller
  ends the share as if from the app.

**iOS and iPadOS** capture through a **Broadcast Upload Extension** (`ios/RaindropBroadcast`), which is
the only way iOS gives an app anything but its own screen.

- The extension is a separate process the system starts when the user taps *Start Broadcast*. It
  knows nothing about the call: it passes each picture of the screen to the app through a Unix socket
  in the folder the two share (the App Group `group.com.raindrop.raindropClient`), in the format
  flutter_webrtc's `FlutterSocketConnectionFrameReader` already reads. **The app is what encodes,
  encrypts and sends**, so encryption is exactly what it is for any other share, and nothing leaves the
  device from the extension.
- Consent is the system's broadcast sheet. It reports nothing — not that it was shown, not that it was
  dismissed — so `prepareScreenCapture` waits for the extension to say it is running, for up to 45 s,
  and that is the answer.
- `BroadcastManager().shouldPublishTrack` is **false**, set at startup. Left on, LiveKit publishes a
  share of its own the moment a broadcast starts — around the handshake, and with none of the settings
  above. The class is not exported by livekit_client 2.13.0 and is imported by path; re-check on a
  bump.
- A broadcast the user stops from the status bar or Control Centre ends the share (`_watchBroadcast`).
  Stopping in the app asks the extension to finish (`requestStop`); iOS then shows its own short alert
  saying the broadcast ended, which is the system's and cannot be suppressed.
- A broadcast started from Control Centre with no call behind it gets no answer from the app, and ends
  itself after 20 s rather than recording a screen for nobody.
- **30 frames a second at most** (`maximumShareFrameRate`). The system holds an extension to about
  50 MB and each frame crosses to the app as a JPEG; that hop does not keep up with 60. The extension
  takes at most 30 a second, never queues one while another is in hand, and fits each inside the 1080p
  box before compressing it. A lower ceiling its sharer picks is applied by the encoder in the app.
- The app stays alive behind another app through the `audio` background mode a call already has.

Backgrounding still turns the **camera** off on a phone. It never touches a share: being behind
another app is what a share is for.

### The handshake, and what can end a share

**The handshake is the camera's.** `VoiceCallController.startScreenShare` tells the server
(`_sendSelfState(share: …)`), waits for the media server's grant — the sound's too, when asked for
(`_awaitShareGrant`) — and only then has the engine capture and publish; nothing is captured for a
share the server refused. A grant that never comes takes the claim back. `stopScreenShare` stops the
engine first, then tells the server. A share already running is switched by starting another.

**The engine can end or trim a share itself**, and the controller then tells the server so the
roster stays true (`_onEngineShare`):
- the shared window closed — `_ShareEndWatch` watches the window list, because the desktop capturers
  report nothing (their stop and error callbacks only log), and waiting for frames to stop would be
  wrong for a screen, which on macOS sends none while nothing on it changes;
- the grant was withdrawn (the permission went, or a mute for everyone took the sound);
- it could not be encrypted — the send-side check covers both screen tracks, and withdraws both;
- the window's sound could not be captured: the picture carries on, and the user is told;
- on iOS, the broadcast behind it ended (`_watchBroadcast`).

On Android the *service* notices a capture the system ended and the controller stops the share
(`CallSessionHost.screenCaptureEnded`); see [On a phone](#on-a-phone). Whichever way a share ends,
`_shareEnded` drops the service's `mediaProjection` type and clears the readout.

**Claims follow the engine, never `voice.state` events** — for the camera as well. An event can arrive
after a newer report has already gone out, and a claim moved back by a stale one would have the next
mute end the camera or the share at the server. Whatever the server takes away on its own it also
takes from the media server's grant, the engine stops what it must, and the controller corrects the
claim from that (`_onEngineShare`, and the camera's listener, which now also reports a camera the
engine stopped for failing to encrypt). Switching what is shared stops the old share before the new
one is claimed, so the sound grant a screen withdraws is never read as the server silencing a live
window.

A share being started is withdrawn by publication, never by source, if it is stopped while
publishing is still in flight — so a stop that lands mid-start leaves nothing published and nothing
capturing.

**Receiving.** Nobody's share is received until it is watched (`setScreenShareWatched`): it is
`disable()`d the moment it is published, picture and sound, so the media server forwards nothing from
it, and the wish outlives the share like a hidden camera does — but not the sharer leaving the call:
`voice.left` for them drops them from `watching` (`_stopWatchingLeaver`), so a share they start after
coming back is a Watch card again, not a stream that resumes unasked. LiveKit reporting them gone is
not enough on its own, because it also does that while they are rejoining after a network drop, and a
share that comes straight back should keep playing. `screenShares` names everybody sharing
something this client trusts, watched or not, so a share can be offered before it is received; an
untrusted one (`untrustedScreenShares`) is never drawn or played. A share's sound has its own volume
(`setScreenShareVolume`), separate from the member's voice, and follows the default volume — so it
goes silent with deafen — until one is set. Hiding somebody's camera only ever touches their camera.

**A viewer can pin a share lower** (`setScreenShareReceiveQuality`: Auto, High, Medium, Low — the
three versions). Auto is the media server choosing, which is right nearly always; the others are for a
metered connection, where what the connection can carry and what its owner wants to pay for are
different answers. It is a ceiling on top of the automatic choice — LiveKit takes the smaller of the
two — so it never asks for more than the connection carries. Local only, kept per sharer for the
call, and dropped with `watching` when they leave it.

**macOS** asks for the Screen Recording permission when the picker opens
(`needsScreenCapturePermission`); refused once, it can only be granted in System Settings → Privacy
& Security → Screen & System Audio Recording, and `VoiceScreenSources.captureAllowed` says so.

## State

| Provider | What | Lifetime |
|---|---|---|
| `voiceCallProvider` (`features/voice/controllers/voice_call_controller.dart`) | The **one** call this client is in, across all servers: server and channel, `joining`/`connected`/`reconnecting`, who is speaking, whether you are muted for everyone or suppressed, the camera (`cameraOn`, `cameraSuppressed`, `cameraBusy`, `videoFeeds`, `untrustedVideo`), a one-shot `notice` for why a call ended, and a dismissible `warning` for something the engine refused mid-call | global, kept alive |
| `voiceRosterProvider(serverId)` (`voice_roster_controller.dart`) | Who is in every call on a server, plus `available`, `maximumParticipants` and `maximumCameraPublishers`; drives the sidebar and the voice view | per server |
| `voiceSettingsProvider` (`voice_settings_controller.dart`) | Your mute/deafen, output volume, devices, echo cancellation / noise suppression / auto gain, and the share quality last chosen (`shareQuality`) | global, persisted |
| `voiceShareLimitProvider` (`voice_call_controller.dart`) | The most a share from this device may be sent at in the call it is in: the server owner's ceiling and the platform's, whichever is lower | derived |
| `voiceShareSendStatsProvider` (`voice_call_controller.dart`) | What this client's share is really going out at, every 2 s while one runs; null otherwise | global |
| `memberAudioProvider` (`member_media_controller.dart`) | Per-member volume, local mute, hidden camera and **share volume** (`MemberMedia.screenVolume`), keyed `serverId/userId` | global, persisted |

**The roster** follows the event stream through `LiveSync`, like every other list. It applies:

- `voice.state` as an upsert (a member is in one call at a time, so this also moves them);
- `voice.left` as a removal;
- `channel.deleted` as dropping that call.

It re-reads after `ready` and after any role event, and polls every 15 s while the stream is down. A
server without the voice service (`unimplemented` on `VoiceService.GetVoiceStatus`) reads as an empty,
unavailable roster.

**The call controller** joins with `VoiceApi.join`, sending your current mute and deafen so nobody
sees you unmuted for a moment. It then creates the engine and connects.

- **It follows the session with `ref.listen`, not `watch`.** Renaming a server rebuilds its session,
  and a watch would tear the call down. It only ends the call when the session is really gone or its
  token changed, and otherwise switches to the rebuilt session's live client.
- **It rejoins after a network drop, and only after a network drop.** A call the network took away
  — Wi-Fi to cellular, a tunnel, a phone that went to sleep — is put back together by
  `_rejoinOrEnd`: five tries over about half a minute (`_rejoinBackoff`), the call staying on screen
  as `reconnecting` the whole time. Each try is a fresh join, so it gets a new token and, on an
  end-to-end encrypted server, a fresh media key; LiveKit has already used up its own reconnects by
  the time this runs. A try that fails is silent — the rejoin speaks for the call once, when it gives
  up.

  It does **not** rejoin after anything somebody decided, because those will decide the same way
  again. It ends the call with a notice when:
  - the engine reports the same account joining from another device;
    (the other side of this is the join button: when the roster lists this person in a call this
    device is not in, another of their devices is, so the button reads **Move the call to this
    device** and says that joining here ends it there — the server keeps one call record per member
    and hands it to the newest join)
  - the server removed this participant, or the call itself ended;
  - `voice.left` arrives for this client, with its reason (`permission_lost`, `channel_deleted`,
    `session_ended`, …);
  - the server refuses a rejoin (`channel_full`, `missing_permission`).

  The shell shows each notice once, as a snackbar.
- **A microphone that will not open does not end the call.** Capture can fail for reasons that have
  nothing to do with the call — another app holding the microphone (on a phone, usually a cellular
  call), or no input device at all — and it is reached from the connect, a settings change and a
  permissions event alike. So `_applyMic` never throws: it reports on `VoiceEngine.microphoneFailures`,
  the call carries on, `VoiceCallState.microphoneFailed` is set, and the mute button shows muted,
  explains why, and **retries** when tapped (`retryMicrophone`) — muting would change nothing anybody
  can hear.
- **Hanging up lets go of every device at once.** The engine does not use `Room.disconnect()`:
  livekit_client 2.13 sends the leave and then waits up to a fixed 10 s for LiveKit to answer with a
  leave of its own, which a client-initiated leave does not reliably get, and stops the local tracks
  only after that. That kept the microphone (and any camera or shared screen) capturing for ten
  seconds after the call had ended on screen, and then threw a `TimeoutException`. Instead,
  `_closeRoom` stops every local track (microphone, camera, the shared screen and its sound), sends
  the leave through the room's engine without waiting, and disposes the room, which closes both peer
  connections and the signalling socket. Raindrop's own `LeaveVoice` is what removes the member for
  everybody else. Nothing about hanging up waits on the network, and nothing throws.
- **Quitting the app leaves the call first.** The controller's `AppLifecycleListener` answers
  `onExitRequested` (Cmd+Q, closing the last window on macOS, closing the window on Windows and Linux)
  with `leaveNow()`, which sends `LeaveVoice` and waits for the media to be released, for at most
  1.5 s so an unreachable server never holds up the quit. `onDetach` tries the same without waiting.
  A client that crashes or is killed cannot do this. The server notices its signalling connection
  close and drops it after `SignalLossGrace` (5 s); see the server's `docs/voice.md`.
- **Moderator mutes come from `voice.state`.** A mute for everyone, or losing `speak`, arrives as
  `voice.state` for you: the controls show you as muted and explain why. When `canPublish` comes back,
  the engine republishes your microphone if you had it on.

**Mute and deafen are settings, not call state.** They persist between calls and across restarts, the
way a headset's mute switch would. The rules:

- Deafening mutes. Undeafening restores the microphone to how it was before (`mutedBeforeDeafen`).
- Unmuting while deafened undeafens too.
- Every change is applied to the engine straight away and reported with `VoiceApi.setSelfState`, so
  everybody's icons follow.

**Volume.** Each remote member plays at `effectiveVolume` (`features/voice/models/member_audio.dart`):
their own volume times the output volume, capped at `maximumVolume` (2.0, i.e. 200%), or 0 while
deafened or locally muted. The controller re-applies it whenever:

- the settings or member audio change;
- the roster changes.

Somebody whose audio arrives before the roster names them plays at the default volume instead. Volume
is applied with flutter_webrtc's `Helper.setVolume` on each remote track, which sets the libwebrtc
source gain: 0 silent, 1 as sent, up to 10. That range is why a report of distortion "at 80" was a
units mistake, and why the cap is 2.

## UI

- **Sidebar** (`features/channels/widgets/channel_sidebar.dart`):
  - Voice channels have their own "+" (the Voice heading shows even when empty if you may create
    channels), and the empty-server state offers both kinds.
  - Each voice channel lists who is in its call underneath (`VoiceParticipantRow`), for everybody who
    can see the channel, with mute/deafen/"muted for everyone" icons and a speaking ring for the call
    you are in.
  - Above your name, `VoiceConnectionBar` shows "Voice connected · channel / server" with a hang-up
    button, whichever server the call is on.
  - Your panel has **mic** and **headset** buttons (`VoiceSelfControls`) that work in or out of a call.
- **Voice view** (`features/voice/widgets/voice_channel_view.dart`) replaces the chat pane when a voice
  channel is selected (`HomeShell` switches on `ChannelType.voice`). It shows:
  - the participants as tiles (`VoiceParticipantTile`), with a green ring on whoever is speaking;
  - a capacity count;
  - a **Join voice** button, or "Switch to this call" if you are in another one. The button is disabled,
    with the reason, without `connect`, when voice is unavailable, or when the call is full;
  - once you are in the call: mute, deafen, **camera**, **share screen** and
    **Disconnect** — labelled when the view is at least 460 wide, an icon-only red hang-up button
    on a phone, where the labelled one pushed the row 31px past the edge (the row also scales
    down rather than overflowing on anything narrower); a banner when a moderator muted you or you can only listen; and a dismissible
    banner when the engine refused something (the state banners have no dismiss, because the state
    would still be true afterwards).
  - a participant with their camera on gets a 16:9 `VoiceVideoTile` instead of the avatar tile, or a
    `VoiceVideoPlaceholder` when it is hidden here or not trusted. The camera and share counts sit
    beside the member count in the top bar, since those limits are separate and much smaller.
  - **screen shares** (`voice_screen_share_tile.dart`), only once you are in the call. A share you are
    not watching is a `VoiceScreenShareCard` among the participants — "*name* is sharing a window,
    with its sound" — with **Watch**; it says "Starting…" until the engine reports the publication,
    and "not encrypted, so it is not shown" for an untrusted one. A watched share takes the **stage**:
    drawn large and whole (`BoxFit.contain`, never mirrored) above a horizontal strip of every other
    watched share, the cards and the participants; tapping another share in the strip brings it
    forward. Its bar has the sharer's name and what they share, a **volume** slider when it carries
    sound (its own, apart from their voice), **Full view** (a full-window route, Esc to close, which
    closes itself once the share ends — stopped, the sharer left, or this client left the call) and **Stop watching**.
  - **while you share**, `VoiceOwnShareBar` above the participants: "You're sharing “Notes”, with its
    sound", and under it what is really going out — "Auto · sending 1080p · 30 fps · 2.1 Mbit/s", or
    "…720p · 24 fps, limited by your connection"; a **quality** button that changes the ceiling
    without stopping the share; a small preview of exactly what everybody sees (foldable, and not
    drawn at all when folded — a local preview of a large screen costs a texture upload every frame;
    folded to begin with on a phone, where it would be a picture of the screen it is on); and **Stop
    sharing**.
  - a watched share's bar also has **Quality, only for you**: Auto, or pinned to a smaller version.

  The camera button is in the layout's button registry (`MainButtons.camera`) *and* hard-wired into
  the in-call controls. **`LayoutConfig.normalize` keeps unknown button ids but never adds new ones**,
  so an existing user's saved `layout.json` will not gain it — the in-call controls are where it is
  always reachable. See [Layout](layout.md). The share button (`MainButtons.screenShare`,
  `VoiceScreenShareButton`) is in the registry, so it can be placed in a toolbar from the layout
  editor, but **not in the default layout**: the user panel's row under your name already holds four
  buttons, and a fifth would not fit the channel list's narrowest width. It is always in the in-call controls.

- **The share picker** (`screen_share_picker.dart`, `showScreenSharePicker`) opens from the share
  button. **Screens** and **Windows**, each a grid of live thumbnails from `openScreenSources()`
  (Raindrop's own windows left out on Windows); double-click shares at once. Under Windows sits the
  checkbox **"Also share this window's sound"** — *the sharer's agreement*: unticked every time the
  picker opens and whenever another window is chosen, and disabled with the reason from
  `windowAudioUnavailableReason` (not available on macOS or Linux yet, needs Windows 11, or the
  window's process tree contains Raindrop). Under Screens: "A whole screen is shared without sound."
  On Share, a chosen window is checked again (`isWindowStillOpen`). On macOS a refused Screen
  Recording permission shows where to allow it instead of an empty grid. Under both sits the
  **quality** (`ShareQualityField`): Auto or a size and a frame rate, a line saying what that comes
  to, and — when the server or the platform caps it — whose cap it is. Unlike the sound checkbox the
  quality is remembered: it is a preference about this device and its connection, not an agreement
  about what is on screen.

  On a phone the same call opens a **sheet** instead: what will be seen (everything), what the system
  asks next, the quality, and Continue.

  **Selecting a channel never joins it**: joining is the button.
- **Narrow layout**: the sidebar lives in a drawer, so a call in progress gets a thin
  `VoiceConnectionBar(compact: true)` above the pane, with mute, deafen and hang-up in it.
- **Member menu** (`voice_member_menu.dart`) opens on right-click on desktop and long press on touch
  (a bottom sheet), on a participant tile or sidebar row. It is not offered on your own entry. It has:
  - **Volume** (0–200%, 5% steps) — of their voice; a shared window's sound has its own slider on the
    share;
  - **Mute** ("only for you");
  - **Mute / Unmute for everyone**, shown only with server-wide `mute_members` (from
    `serverPermissionsProvider`).

  The menu entry is a custom `PopupMenuEntry` rather than a `PopupMenuItem`, so dragging the slider
  does not close the menu.
- **Settings → Voice & audio** (`voice_settings_section.dart`):
  - microphone and speakers (desktop only; on phones the OS routes audio, and the earpiece/
    loudspeaker choice is a button in the call bar instead — see [Android and iOS](mobile.md));
  - output volume;
  - echo cancellation, noise suppression and automatic gain.

  There is **no microphone volume**. Neither LiveKit's SDK nor flutter_webrtc offers an input gain on
  desktop, so automatic gain control is how a quiet microphone gets evened out.

Speaking and "connected" colours reuse `AppSurfaces.onlineIndicator`, so no theme JSON had to change.

## Platform setup

| Platform | What voice needed |
|---|---|
| macOS | `com.apple.security.device.audio-input`, `com.apple.security.network.client` **and `com.apple.security.network.server`** in *both* entitlements files; `NSMicrophoneUsageDescription` in `Info.plist`. Screen sharing needs no entitlement or usage string: the system asks for Screen Recording itself |
| iOS | `NSMicrophoneUsageDescription`, and the `audio` background mode so a call survives leaving the screen. Screen sharing: the `RaindropBroadcast` extension target, the App Group in both targets' entitlements, and `RTCAppGroupIdentifier` + `RTCScreenSharingExtension` in `Info.plist` — see [Android and iOS](mobile.md#sharing-the-screen) |
| Android | `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `BLUETOOTH_CONNECT` (+ legacy `BLUETOOTH` ≤ API 30), and `INTERNET`/`ACCESS_NETWORK_STATE` in the **main** manifest (release builds had no network access before). Plus `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE` and `POST_NOTIFICATIONS` for the ongoing-call service, and `FOREGROUND_SERVICE_MEDIA_PROJECTION` with the service typed `microphone\|mediaProjection` for screen sharing |
| Windows, Linux | nothing. Sharing a window's sound needs Windows 11 |

flutter_webrtc and livekit_client ship Swift Package Manager manifests, so the Apple builds stay on
SPM with no Podfile. `native/raindrop_camera_effects` is an SPM package too, and depends on
flutter_webrtc's own `flutter-webrtc` and `WebRTC` products — the same cross-plugin dependency
`livekit_client` already declares, which is what lets our Objective-C include flutter_webrtc's public
headers without vendoring or forking anything. On Android it is a plain `com.android.library` with
`compileOnly project(':flutter_webrtc')` and `compileOnly` on the WebRTC AAR: both are already in the
app, and shipping a second copy of the AAR would be tens of megabytes of duplicate classes.

`com.apple.security.network.server` is the one that is easy to get wrong, because nothing about it
says "voice". Under the App Sandbox it is what permits `bind()`, and WebRTC binds UDP and TCP
sockets both to gather ICE candidates and to receive audio; `network.client` covers only outgoing
connections. Without it a call looks *almost* fine: the signalling WebSocket connects (it is an
outgoing connection), the server admits the participant, and then no media connection is ever
established — the only ICE candidates the client can offer are `tcp … typ host tcptype active` ones
on port 9, and no connectivity check can succeed. LiveKit logs the participant joining and being
removed again without a connection, and the client retries the whole join in a loop. Release builds
carried `network.client` alone until this was found, so voice worked from `flutter run` and failed
in release builds only — the same trap the Android manifest fell into.

**Calls keep running on a phone that is not on screen**, which needs opposite things on the two
platforms and so goes through `CallSessionHost` (`core/voice/call_session_host.dart`) rather than
being branched on at the call site: iOS needs only the background mode above, Android a foreground
service of type `microphone`. The media stack is also initialized once at startup
(`initializeVoice()` from `main`), because on a phone the kind of audio session a call needs is fixed
when the media library first initializes, not when a call starts. Full detail:
[Android and iOS](mobile.md).

## Not yet

- Push-to-talk.
- **Sixty frames a second from iOS** — its screen comes through a broadcast extension, which does not
  keep up; see [On a phone](#on-a-phone).
- **A hardware video codec for shares.** 1080p at 60 is software VP8, which is costly; H.264 would be
  cheap on most devices but the codec is a security setting here and would need the frame cryptor
  re-read for it first.
- **Sound from a phone's screen.** A whole screen is shared without sound everywhere.
- **A window's sound on macOS and Linux** ([why](#screen-sharing)).
- **Camera effects on Windows and Linux.** They run on macOS, iOS and Android; see
  [Camera effects](#camera-effects). Those two have no chain between the capturer and the video
  source to put a processor into, so `canUseCameraEffects` is false there and the sheet says so.
- Microphone volume (no API for it; see above).
- CallKit / ConnectionService: a call never rings, and does not show in the phone's own call UI.

## Related

- The server's [Voice doc](../../RaindropServer/docs/voice.md): permissions, reconciliation, the relay,
  the Voice API.
- [Channels](channels.md): the sidebar the calls are listed in.
- [Live updates](live-updates.md): how `voice.*` events arrive.
- [Android and iOS](mobile.md): background calls, the speaker, and what phones still cannot do.
- [Settings](settings.md) and [Storage](storage.md): where voice preferences live.
