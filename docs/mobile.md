# Android and iOS

RaindropClient runs on phones with the same code that runs on desktop. There is no mobile fork, no
second widget tree and no "mobile mode": the shell is
[responsive by width](native-feel-per-platform.md#the-responsive-shell), the controls
[adapt per platform](native-feel-per-platform.md), and everything in `core/` and `features/` is
shared. What this page covers is the part that *could not* be shared — the handful of places where a
phone genuinely behaves differently from a window on a desk.

There are four of them:

1. **A phone stops an app that leaves the screen.** A call has to ask not to be, and a connection has
   to be rebuilt on the way back.
2. **A phone has two speakers**, an earpiece and a loudspeaker, and no device picker.
3. **A phone shares its whole screen or nothing**, and each system has its own ceremony for it.
4. **A phone is built differently** — a different toolchain, permissions declared up front and asked
   for at runtime, and a store's worth of packaging.

## Background voice

A call keeps running when you switch apps, lock the phone or open something else. Getting there means
opposite things on the two platforms, so neither the call controller nor the voice engine says any of
it out loud — both go through [`CallSessionHost`](../lib/core/voice/call_session_host.dart):

| | What it takes | Where |
|---|---|---|
| **iOS** | The `audio` background mode, plus an active `playAndRecord` audio session — which LiveKit holds for the length of the call. Nothing at runtime to keep it running; at runtime the host only *shows* the call, as a Live Activity (`IosCallSessionHost`). | `ios/Runner/Info.plist`, `ios/Runner/CallActivity.swift`, `ios/RaindropLiveActivity/` |
| **Android** | A foreground service of type `microphone`, with a notification, for as long as the call lasts. | `android/app/src/main/kotlin/…/CallForegroundService.kt` |
| **Desktop** | Nothing. Windows are not suspended for being in the background. | — |

`CallSessionHost` is the seam between those. `VoiceCallController` begins a session once the media
connection is actually up — so a join that failed never leaves a notification behind — and ends it in
`_teardown`, however the call ended. Every platform now has a real host (`AndroidCallSessionHost`,
`IosCallSessionHost`, `DesktopCallSessionHost`); `InactiveCallSessionHost` is left for tests and any
platform not listed, so there is no branch at the call site. The host is behind `callSessionHostProvider`, which is what to
override to announce a call differently.

### Showing the call, and the controls coming back

The session is also how a call is going to be *shown* outside the app (see
[Background and live calls](background-and-live-calls.md)), so what it carries is no longer a title and
a line of text but the whole call as a glance shows it: `CallSessionDescription` holds the title and
body, `connectedAt`, `micOn`, `deafened`, `reconnecting`, `participants`, `sharingScreen`, `encrypted`,
`concealed` and `showOutsideApp`. Three details matter to whoever draws it:

- **Nothing ticks.** The timer is `connectedAt`, and each surface draws its own clock from it. A
  rejoined call keeps its `connectedAt`, so the timer does not start again.
- **`micOn` is what others hear.** It is false when the person muted themselves, a moderator muted
  them, they are suppressed, or the microphone failed to open — the same cases in which the call bar's
  mute button reads muted.
- **`concealed` means the app lock is engaged.** The title is then the generic "In a voice call", the
  body is empty, and a surface must name nothing else either.

The description is compared by value and sent over the channel with `toMap()` (`connectedAt` as
milliseconds since the epoch). `VoiceCallController` opens the session once the call connects and sends
it again only when it really changed.

The way back is `CallSessionHost.actions`, a stream of `CallSessionAction` (`toggleMute`,
`toggleDeafen`, `leave`) for the controls pressed on the surface outside the app. The controller applies
each as the call bar's button would, so a mute pressed while the microphone has failed retries it. The
channel hosts (`ChannelCallSessionHost`, which Android's, iOS's and the desktops' extend) relay the
channel method `action`, whose argument is the action's name; a name this build does not know is
ignored. **The Kotlin side does not send it yet**; the desktops and iOS do.

`CallSessionHost.showsCallOutsideApp` says whether the host shows the call somewhere the person may do
without, which is what puts the setting in [Settings](settings.md#background). It is true on iOS only,
where the call is a Live Activity and the setting reads **Show calls as a Live Activity**. It is false on
the desktops, which always show their call, and on Android, where the ongoing notification is the price
of the call running at all, so it is not offered as something to turn off yet.

### The iOS Live Activity

On an iPhone or iPad the call is shown as a Live Activity: the Lock Screen on every iPhone, the Dynamic
Island on those that have one. `IosCallSessionHost` sends the description to `ios/Runner/CallActivity.swift`,
which starts, updates and ends the activity (local only, `pushType: nil`, so no push server is involved)
and relays the Mute, Deafen and Leave buttons back as `action`; `ios/RaindropLiveActivity/` draws it. What
a person sees, how it is built and what it cannot do are in
[Background and live calls](background-and-live-calls.md#on-an-iphone-or-ipad). In short: iOS starts an
activity only for an app in the foreground (met, because joining is in the foreground and a rejoin keeps
the session open); updates made while the app is backgrounded may be throttled, though the timer is
drawn by the system and is not affected; an activity lasts at most 8 hours; the buttons need iOS 17; and
swiping the app away ends the call and its activity. **Not yet seen with a real call on a device or
simulator.**

Two rules the Android side follows, both because the call's real state lives in Dart:

- The service holds no call state. It is told what to show and when to stop, nothing more.
- It is `START_NOT_STICKY`. A service the system restarted on its own would be showing a notification
  for a call that is no longer happening.

**The notification cannot be dismissed** to end a call (`setOngoing`); hanging up is done in the app,
and tapping the notification comes back to it. Denying the notification permission does not stop a
call — Android 13+ just shows nothing and the service still runs.

**The permission is asked the first time a call begins** (`MainActivity.askForNotifications`, on the
session's `begin`), which is the moment the notification means something. Until this was added it was
declared and never requested, so on Android 13+ no call ever showed one. A notification posted before
the answer is dropped by the system, so a yes re-issues it (`CallForegroundService.refresh`). Android
stops asking by itself after two refusals.

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

**The operating-system session stays open across a rejoin.** The controller tears the engine down
between tries but keeps the session (`_teardown(keepSession: true)`) and describes it as
`reconnecting`; it is ended only when the call settles. Ending it and opening a new one would not
work: Android will not start a microphone foreground service again from the background, and iOS will
not start a Live Activity from there either, so a call dropped while the app is off screen could never
be shown again.

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
deliberately *not* in the shipped layout: the user panel's row of buttons under the name already holds
four, and a fifth would not fit the channel list's narrowest width. The button draws nothing off a phone — the same trick the
members toggle uses — so placing it costs desktop nothing.

## Sharing the screen

A phone or a tablet can share its screen into a call. What that means, the order things happen in and
why are in [Voice](voice.md#on-a-phone); this is what each platform needed.

| | What it takes | Where |
|---|---|---|
| **Android** | The system's capture consent before every share; the call's foreground service taking the `mediaProjection` type for as long as the share runs; a watch on the capture's virtual display, because nothing reports the system ending a capture. | `CallForegroundService.kt`, `MainActivity.kt`, the manifest |
| **iOS, iPadOS** | A Broadcast Upload Extension — a second target — and an App Group both it and the app are entitled to, through which each picture is handed to the app. | `ios/RaindropBroadcast/`, `ios/Runner/Runner.entitlements`, `Info.plist` |
| **Desktop** | Nothing here: see [Voice](voice.md#screen-sharing). | — |

Both go through seams that already existed: the consent is `VoiceEngine.prepareScreenCapture`, and
Android's service is told through `CallSessionHost` (`setScreenCapture`, `screenCaptureEnded`), which
is inert everywhere else.

### The iOS extension

`ios/RaindropBroadcast` is its own target, embedded in the app (`Runner.app/PlugIns`):

- `SampleHandler.swift` — the whole of it. It receives the screen from ReplayKit and writes each frame
  to the app over a Unix socket, in the format flutter_webrtc reads on the other side. It never
  touches the network: the app encodes, encrypts and sends.
- `Info.plist` — the extension point (`com.apple.broadcast-services-upload`), and
  `RTCAppGroupIdentifier`, the same value as in the app's.
- `RaindropBroadcast.entitlements` and `Runner/Runner.entitlements` — the App Group
  `group.com.raindrop.raindropClient`. Neither process can reach the shared folder unless both name it.
- `Broadcast.xcconfig` — only Flutter's generated variables, for the two version numbers (an extension
  must carry the same version as its app). Deliberately *not* Flutter's `Debug`/`Release.xcconfig`,
  which also pull in the CocoaPods settings and would link every plugin into a process with 50 MB to
  live in. It does include `Flutter/Warnings.xcconfig`, so the extension's code fails on warnings as
  Runner's does.

The target was added to `Runner.xcodeproj` by `tool/ios/add_broadcast_extension.rb`, which is kept as
the record of what it needed and to run again if the project is ever regenerated. Its *Embed
Foundation Extensions* phase sits **before** Flutter's *Thin Binary*: after it, Xcode reports a cycle
in Runner's build.

**Signing.** The extension is `com.raindrop.raindropClient.RaindropBroadcast`, under the app's own id
and the same team. On the Apple Developer account it needs its own App ID, and both App IDs need the
App Groups capability with `group.com.raindrop.raindropClient`. Xcode's automatic signing registers
all three the first time the app is built for a device with the team signed in; a release pipeline that
signs with explicit profiles needs a second profile for the extension. CI builds `--no-codesign`,
which compiles and embeds the extension without any of that.

**It does not run in the Simulator.** ReplayKit broadcasts need a real device, so this is one part of
the app that can only be tried on one.

**A second extension.** `ios/RaindropLiveActivity` is a widget extension (`com.apple.widgetkit-extension`)
for the call's [Live Activity](background-and-live-calls.md#on-an-iphone-or-ipad), added by
`tool/ios/add_live_activity_extension.rb` and embedded in the same *Embed Foundation Extensions* phase.
It is `com.raindrop.raindropClient.RaindropLiveActivity`, under the same team, and needs its own App ID
on the developer account — but no App Group or other capability. Automatic signing registers it; a
release pipeline with explicit profiles needs a profile for it too, so three in all. Its deployment
target is 16.2 while the app stays at 15.0 (Runner weak-links ActivityKit and AppIntents), and CI's
`--no-codesign` builds compile and embed it like the other.

## Building

Both build locally (an Android emulator or device, and an iPhone — see [On a physical iPhone](#on-a-physical-iphone)),
and **CI proves them on every push**: `.github/workflows/ci.yml` builds `android` on Linux and `ios` on macOS alongside the desktop targets.

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

#### On a physical iPhone

- **Signing is automatic**, with the developer's own team (`DEVELOPMENT_TEAM` in
  `ios/Runner.xcodeproj`; a free Personal Team is enough). Xcode has to be signed in to that Apple ID
  (Xcode > Settings > Accounts), or `flutter build ios` fails with "No Accounts" / "No profiles for
  'com.raindrop.raindropClient' were found". The phone must also be paired with the Mac once, by cable
  or from Xcode's Devices window, so its UDID gets into the Xcode-managed profile.
- **Build** with `flutter build ios --release`; the app is `build/ios/iphoneos/Runner.app`.
- **Install wirelessly** with the phone paired, on the same network and unlocked. Find its UDID, then
  install:

  ```bash
  xcrun devicectl list devices
  xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
  ```

- **A free Personal Team** accepts the App Group (`group.com.raindrop.raindropClient`, shared with the
  `RaindropBroadcast` extension). Its profiles expire after 7 days, so the app has to be reinstalled
  then. On the first install, trust the developer profile in Settings > General > VPN & Device
  Management.
- **Decline Xcode's "Update to recommended settings"** when it opens the project (or revert
  `ios/Runner.xcodeproj` if it was accepted). It replaces the targets' fixed `IPHONEOS_DEPLOYMENT_TARGET`
  values (15.0) with `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`,
  which CocoaPods 1.17 cannot parse (`pod install` fails with "Malformed version number string
  $(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)"), and moves `DEVELOPMENT_TEAM` to the project level.

## Permissions

Declared up front, asked for when first used, and every one of them optional except the network:

| Permission | Why | Without it |
|---|---|---|
| Microphone | Talking in a voice channel | Join and listen; you are silent |
| Camera | Scanning another device's [link code](crypto.md) | Type the code instead |
| Photos (iOS) | Attaching a photo to a message | Attach from Files instead |
| Notifications (Android 13+) | The ongoing-call notification | The call still runs, unshown |
| Screen capture (asked by the system, every share) | Sharing your screen into a call | You can watch shares, not start one |
| Bluetooth (Android) | A Bluetooth headset in a call | The phone's own speakers |

iOS usage strings live in `ios/Runner/Info.plist` and are written to say what Raindrop does with each
one, not to recite the API.

## What phones still do not do

- **No notifications for new messages** while the app is closed. Raindrop is self-hosted and has no
  push infrastructure; delivering them would mean either FCM/APNs — per-deployment credentials, and
  message metadata passing through Google or Apple, which is at odds with a server whose whole point
  is that it is yours — or a socket the OS will not let an app keep. See
  [the roadmap](roadmap.md).
- **No CallKit or ConnectionService**: a call is started from inside the app, and never rings. On an
  iPhone that also means no green call pill in the status bar; the system shows its own microphone
  indicator.
- **Android shows no promoted call yet** (CallStyle, Live Updates, the Now Bar): only the ongoing
  notification. An iPhone's call is a Live Activity, but its buttons need iOS 17 and it has not yet been
  seen with a real call. See [Background and live calls](background-and-live-calls.md).
- **Sixty frames a second from an iPhone or iPad's screen**, and **the sound of a shared screen** on
  either system. See [Voice](voice.md#on-a-phone).
- **Push-to-talk** is missing on every platform, not only here.

## Related

- [Native feel per platform](native-feel-per-platform.md) — the responsive shell and the adaptive
  controls these build on.
- [Members & presence](members-presence.md#rendering) — on a phone the member list is the right-hand
  drawer (the top bar's **Members** button, or a swipe from the right edge); nothing about it is
  phone-specific, it is the narrow layout every window under 680px gets.
- [Voice](voice.md) — calls in full, of which the background half is here.
- [Live updates](live-updates.md) — the event stream that `resubscribe()` refreshes.
- [Roadmap](roadmap.md) — what is still missing.
