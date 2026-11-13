# Android and iOS

RaindropClient runs on phones with the same code that runs on desktop. There is no mobile fork, no
second widget tree and no "mobile mode": the shell is
[responsive by width](native-feel-per-platform.md#the-responsive-shell), the controls
[adapt per platform](native-feel-per-platform.md), and everything in `core/` and `features/` is
shared. What this page covers is the part that *could not* be shared — the handful of places where a
phone genuinely behaves differently from a window on a desk.

There are three of them:

1. **A phone stops an app that leaves the screen.** A call has to ask not to be, and a connection has
   to be rebuilt on the way back.
2. **A phone has two speakers**, an earpiece and a loudspeaker, and no device picker.
3. **A phone is built differently** — a different toolchain, permissions declared up front and asked
   for at runtime, and a store's worth of packaging.

## Background voice

A call keeps running when you switch apps, lock the phone or open something else. Getting there means
opposite things on the two platforms, so neither the call controller nor the voice engine says any of
it out loud — both go through [`CallSessionHost`](../lib/core/voice/call_session_host.dart):

| | What it takes | Where |
|---|---|---|
| **iOS** | The `audio` background mode, plus an active `playAndRecord` audio session — which LiveKit holds for the length of the call. Nothing at runtime. | `ios/Runner/Info.plist` |
| **Android** | A foreground service of type `microphone`, with a notification, for as long as the call lasts. | `android/app/src/main/kotlin/…/CallForegroundService.kt` |
| **Desktop** | Nothing. Windows are not suspended for being in the background. | — |

`CallSessionHost` is the seam between those. `VoiceCallController` begins a session once the media
connection is actually up — so a join that failed never leaves a notification behind — and ends it in
`_teardown`, however the call ended. Platforms with nothing to do get `InactiveCallSessionHost`, so
there is no branch at the call site. The host is behind `callSessionHostProvider`, which is what to
override to announce a call differently.

Two rules the Android side follows, both because the call's real state lives in Dart:

- The service holds no call state. It is told what to show and when to stop, nothing more.
- It is `START_NOT_STICKY`. A service the system restarted on its own would be showing a notification
  for a call that is no longer happening.

**The notification cannot be dismissed** to end a call (`setOngoing`); hanging up is done in the app,
and tapping the notification comes back to it. Denying the notification permission does not stop a
call — Android 13+ just shows nothing and the service still runs.

## Coming back from the background

While a phone has an app suspended, it quietly misses things, and nothing announces it:

- **Nothing is received while suspended.** Events that arrive in that time are simply missed, and the
  server replays nothing.

So `serverEventsProvider` listens for the return to the foreground and calls
[`EventStream.resubscribe()`](../lib/core/network/event_stream.dart), which asks the server for a fresh
`ready` on the open stream. The `ready` is what every controller re-reads on, so the client catches up
without tearing the stream down. See [Live updates](live-updates.md).

Desktop is unaffected: its windows are never suspended, so the state simply stays `resumed` and none
of this fires.

## A call that drops picks itself back up

Changing network — Wi-Fi to cellular, or a tunnel — is ordinary on a phone and used to end the call.
`VoiceCallController._rejoinOrEnd` now rejoins instead, five times over about half a minute
(`_rejoinBackoff`), with the call staying on screen as `reconnecting` throughout.

Each try is a fresh join: a new token from the server, and on an end-to-end encrypted server a fresh
media key, since the group may have moved on. LiveKit has already exhausted its *own* reconnects by
the time this runs, which is why picking the call up means joining again rather than waiting.

What is **not** retried is anything somebody decided: replaced by another device, removed, the call
ended, or a server refusal that will refuse again (the channel is gone, the call filled up, the
member may no longer connect). Those end the call with a notice, as before. See [Voice](voice.md).

## The speaker

Phones route audio themselves and the voice library cannot pick a device there, so
`canChooseAudioDevices` is false and Settings shows no device pickers. What a phone *does* need is the
choice desktop does not have: earpiece or loudspeaker.

`VoiceSpeakerphoneButton` sits beside mute and deafen, and like them it is a remembered setting
(`VoiceSettings.speakerphone`) rather than call state, so a call starts out of whichever one the last
call was left on. **It defaults to the loudspeaker**: a call joined from a channel list is one you are
listening to, not one held to your ear. A wired or Bluetooth headset still wins over either.

It rides in the **call bar** (`VoiceSelfControls`, beside mute and deafen), which on a phone is the
thin strip above the chat whenever a call is up — the moment the choice matters. It is registered as a
[layout](layout.md) button too (`MainButtons.speakerphone`), so it can be put in a toolbar, but it is
deliberately *not* in the shipped layout: the sidebar's user panel is 240px wide and a fourth button
there leaves no room for the name beside it. The button draws nothing off a phone — the same trick the
members toggle uses — so placing it costs desktop nothing.

## Building

Neither toolchain is set up on the reference dev machine, so **CI is where these two are proven**:
`.github/workflows/ci.yml` builds `android` on Linux and `ios` on macOS alongside the desktop targets.

```bash
flutter run -d ios          # or a device/simulator id from `flutter devices`
flutter run -d android
flutter build apk --release
flutter build ipa
```

Both compile the Rust crypto core ([`../RaindropCrypto`](../../RaindropCrypto/docs/README.md))
through cargokit, so `rustup` has to be on `PATH` — and for Android, the target per ABI:

```bash
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
```

### Android

- **`minSdk` is 26** (Android 8.0), above Flutter's own default of 24. The call's foreground service
  needs `startForegroundService` and notification channels, both API 26, and guarding those for
  Android 7 would mean branches for a version no longer in use. The plugins' own floors are lower.
- **ABIs** are `arm64-v8a`, `armeabi-v7a` and `x86_64` (`abiFilters`) — every one is another full Rust
  build, and no current device or emulator image needs 32-bit x86.
- **Release signing** reads `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`,
  `keyPassword`), which is not in the repository. Without it a release build falls back to the debug
  keys, so `flutter build apk --release` still works for testing; such a build cannot be published.
- **Releases** attach `RaindropClient-<version>-android.apk` (built by `.github/workflows/release.yml`).
  It is signed with the release key when the repository has the secrets `ANDROID_KEYSTORE_BASE64`
  (the `.jks`, base64-encoded), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and
  `ANDROID_KEY_PASSWORD`; without them it carries the runner's throwaway debug key, so a newer release
  only installs after the old one is uninstalled. The `versionCode` comes from the tag (1.2.3 → 10203).

### iOS

- **Deployment target 15.0**, which LiveKit requires.
- The Rust plugin builds through **CocoaPods** (cargokit supports nothing else), while the other
  plugins use Swift Package Manager. Both run; see the note in
  [`CLAUDE.md`](../CLAUDE.md).
- CI builds `--no-codesign`, which still compiles the Rust core for arm64 and links every pod — the
  parts that actually break.

## Permissions

Declared up front, asked for when first used, and every one of them optional except the network:

| Permission | Why | Without it |
|---|---|---|
| Microphone | Talking in a voice channel | Join and listen; you are silent |
| Camera | Scanning another device's [link code](crypto.md) | Type the code instead |
| Photos (iOS) | Attaching a photo to a message | Attach from Files instead |
| Notifications (Android 13+) | The ongoing-call notification | The call still runs, unshown |
| Bluetooth (Android) | A Bluetooth headset in a call | The phone's own speakers |

iOS usage strings live in `ios/Runner/Info.plist` and are written to say what Raindrop does with each
one, not to recite the API.

## What phones still do not do

- **No notifications for new messages** while the app is closed. Raindrop is self-hosted and has no
  push infrastructure; delivering them would mean either FCM/APNs — per-deployment credentials, and
  message metadata passing through Google or Apple, which is at odds with a server whose whole point
  is that it is yours — or a socket the OS will not let an app keep. See
  [the roadmap](roadmap.md).
- **No CallKit or ConnectionService**: a call is started from inside the app, and never rings.
- **Push-to-talk, camera and screen sharing** are missing on every platform, not only here.

## Related

- [Native feel per platform](native-feel-per-platform.md) — the responsive shell and the adaptive
  controls these build on.
- [Voice](voice.md) — calls in full, of which the background half is here.
- [Live updates](live-updates.md) — the event stream that `resubscribe()` refreshes.
- [Roadmap](roadmap.md) — what is still missing.
