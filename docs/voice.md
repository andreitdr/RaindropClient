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

**Who can share.** The desktops (`canShareScreen`). Phones can watch but not share: showing another
app sends Raindrop to the background, and until calls keep running there the share would stop the
moment it started.

**Whose sound can be shared** — `windowAudioUnavailableReason(windowId)` in `platform_info.dart`:

| Platform | A window's sound |
|---|---|
| Windows 11 (build 20348+) | Yes. flutter_webrtc already captures it with WASAPI *process-tree* loopback into a separate track, published as `screenShareAudio` |
| Windows 10 | No: its audio engine cannot separate one app's sound from everything else's |
| macOS | Not yet. Apple's WebRTC build has no custom audio source, so the only way without a fork is mixing it into the microphone track — decided against |
| Linux | Not yet. flutter_webrtc's capture records the whole default output, Raindrop's own call included, and ignores which window was chosen; it needs a change in flutter_webrtc itself |

**The process-tree guard (Windows).** The capture takes the window's process *and everything it
started*. That is right for a browser, whose sound comes from a child process, and badly wrong for
Explorer, which started nearly everything — Raindrop included. So sound is refused for Raindrop's own
windows and for any window whose process is one of Raindrop's ancestors
(`windowAudioRefusal`, answered by `core/platform/windows_processes.dart` over `dart:ffi`: the
window's owner, and a Toolhelp32 walk up from this process). A UWP app's window belongs to
`ApplicationFrameHost`, whose tree does not contain the app, so it shares silently. And if the window
has closed by the time sharing starts, flutter_webrtc falls back to *all* sound except Raindrop's —
so the window is checked again (`isWindowStillOpen`) right before sharing.

**The 1080p cap is enforced on the sender, by us.** livekit_client cannot: on desktop it works out a
share's encodings from the size it *asked* for, not the size it got (`getSettings()` is read on web
and mobile only), and never scales the top layer below the source. The desktop capturers ignore
size constraints too, and macOS captures at the display's size in points. Left alone, a 4K screen goes
out at 4K. `_ScreenSizeGuard` reads the size actually being captured from the sender's `media-source`
statistic (the largest encoded layer, scaled back up, if that is missing), and sets every layer's
`scaleResolutionDownBy` to LiveKit's own value times `screenShareScale` — the picture fitted inside
1920×1080, turned for a portrait source, never scaled up. It looks every 250 ms until it has a size
and every 2 s after, since windows are resized. For the first quarter-second a share can go out
unscaled; the 2.5 Mbit/s ceiling bounds the bandwidth even then.

**How a share is sent** (`_screenPublish`): VP8 pinned for both codecs (the codec is a security
setting, see [Codecs](#codecs-and-the-frame-cryptor)), simulcast with a half-size layer, 15 fps, 2.5
Mbit/s, and `maintainResolution` — under congestion a share drops frames rather than going soft,
because blurry text is unreadable and slightly late text is not. A window's sound goes as music
(`presetMusic`, no DTX), not with the microphone's speech settings, which would cut a film's quiet
passages to nothing.

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
- the window's sound could not be captured: the picture carries on, and the user is told.

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
it, and the wish outlives the share like a hidden camera does. `screenShares` names everybody sharing
something this client trusts, watched or not, so a share can be offered before it is received; an
untrusted one (`untrustedScreenShares`) is never drawn or played. A share's sound has its own volume
(`setScreenShareVolume`), separate from the member's voice, and follows the default volume — so it
goes silent with deafen — until one is set. Hiding somebody's camera only ever touches their camera.

**macOS** asks for the Screen Recording permission when the picker opens
(`needsScreenCapturePermission`); refused once, it can only be granted in System Settings → Privacy
& Security → Screen & System Audio Recording, and `VoiceScreenSources.captureAllowed` says so.

## State

| Provider | What | Lifetime |
|---|---|---|
| `voiceCallProvider` (`features/voice/controllers/voice_call_controller.dart`) | The **one** call this client is in, across all servers: server and channel, `joining`/`connected`/`reconnecting`, who is speaking, whether you are muted for everyone or suppressed, the camera (`cameraOn`, `cameraSuppressed`, `cameraBusy`, `videoFeeds`, `untrustedVideo`), a one-shot `notice` for why a call ended, and a dismissible `warning` for something the engine refused mid-call | global, kept alive |
| `voiceRosterProvider(serverId)` (`voice_roster_controller.dart`) | Who is in every call on a server, plus `available`, `maximumParticipants` and `maximumCameraPublishers`; drives the sidebar and the voice view | per server |
| `voiceSettingsProvider` (`voice_settings_controller.dart`) | Your mute/deafen, output volume, devices, and echo cancellation / noise suppression / auto gain | global, persisted |
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
- **It never rejoins automatically.** It ends the call with a notice when:
  - the engine reports the same account joining from another device;
  - the server removed this participant, or the call itself ended;
  - `voice.left` arrives for this client, with its reason (`permission_lost`, `channel_deleted`,
    `session_ended`, …).

  A network failure also ends the call with a notice. The shell shows each notice once, as a snackbar.
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
  - once you are in the call: mute, deafen, **camera**, **share screen** (desktop only) and
    **Disconnect**; a banner when a moderator muted you or you can only listen; and a dismissible
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
    says so when the share ends) and **Stop watching**.
  - **while you share**, `VoiceOwnShareBar` above the participants: "You're sharing “Notes”, with its
    sound", a small preview of exactly what everybody sees (foldable, and not drawn at all when folded
    — a local preview of a large screen costs a texture upload every frame), and **Stop sharing**.

  The camera button is in the layout's button registry (`MainButtons.camera`) *and* hard-wired into
  the in-call controls. **`LayoutConfig.normalize` keeps unknown button ids but never adds new ones**,
  so an existing user's saved `layout.json` will not gain it — the in-call controls are where it is
  always reachable. See [Layout](layout.md). The share button (`MainButtons.screenShare`,
  `VoiceScreenShareButton`) is in the registry, so it can be placed in a toolbar from the layout
  editor, but **not in the default layout**: the user panel under your name already holds four
  buttons in a 240-wide sidebar. It is always in the in-call controls, and draws nothing where
  sharing is impossible (phones), whichever toolbar it is put in.

- **The share picker** (`screen_share_picker.dart`, `showScreenSharePicker`) opens from the share
  button. **Screens** and **Windows**, each a grid of live thumbnails from `openScreenSources()`
  (Raindrop's own windows left out on Windows); double-click shares at once. Under Windows sits the
  checkbox **"Also share this window's sound"** — *the sharer's agreement*: unticked every time the
  picker opens and whenever another window is chosen, and disabled with the reason from
  `windowAudioUnavailableReason` (not available on macOS or Linux yet, needs Windows 11, or the
  window's process tree contains Raindrop). Under Screens: "A whole screen is shared without sound."
  On Share, a chosen window is checked again (`isWindowStillOpen`). On macOS a refused Screen
  Recording permission shows where to allow it instead of an empty grid.

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
  - microphone and speakers (desktop only; on phones the OS routes audio);
  - output volume;
  - echo cancellation, noise suppression and automatic gain.

  There is **no microphone volume**. Neither LiveKit's SDK nor flutter_webrtc offers an input gain on
  desktop, so automatic gain control is how a quiet microphone gets evened out.

Speaking and "connected" colours reuse `AppSurfaces.onlineIndicator`, so no theme JSON had to change.

## Platform setup

| Platform | What voice needed |
|---|---|
| macOS | `com.apple.security.device.audio-input`, `com.apple.security.network.client` **and `com.apple.security.network.server`** in *both* entitlements files; `NSMicrophoneUsageDescription` in `Info.plist`. Screen sharing needs no entitlement or usage string: the system asks for Screen Recording itself |
| iOS | `NSMicrophoneUsageDescription`. **No** background audio mode: calls are foreground-only for now |
| Android | `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `BLUETOOTH_CONNECT` (+ legacy `BLUETOOTH` ≤ API 30), and `INTERNET`/`ACCESS_NETWORK_STATE` in the **main** manifest (release builds had no network access before). No foreground service yet |
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

## Not yet

- Background audio on phones (iOS background mode, Android microphone foreground service).
- Push-to-talk.
- Rejoining automatically after a network drop (the call ends with a notice; you join again).
- **Sharing from a phone** — needs background calls first; phones can watch.
- **A window's sound on macOS and Linux** ([why](#screen-sharing)).
- **Camera effects on Windows and Linux.** They run on macOS, iOS and Android; see
  [Camera effects](#camera-effects). Those two have no chain between the capturer and the video
  source to put a processor into, so `canUseCameraEffects` is false there and the sheet says so.
- Microphone volume (no API for it; see above).

## Related

- The server's [Voice doc](../../RaindropServer/docs/voice.md): permissions, reconciliation, the relay,
  the Voice API.
- [Channels](channels.md): the sidebar the calls are listed in.
- [Live updates](live-updates.md): how `voice.*` events arrive.
- [Settings](settings.md) and [Storage](storage.md): where voice preferences live.
