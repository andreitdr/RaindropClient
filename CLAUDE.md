# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation wiki

[`docs/`](docs/README.md) is a per-feature documentation wiki for this project, meant to stay current.
**Whenever you change a feature or add a new one — a new screen, a changed controller, a new provider,
a new dependency, a change to how the client talks to the server — update the matching file(s) under
`docs/` as part of that same change**, not as a follow-up. If nothing existing fits, add a new file and
link it from `docs/README.md`. If a change affects the server's API contract, also update the matching
doc under [`../RaindropServer/docs/`](../RaindropServer/docs/README.md).

RaindropClient is the Flutter client for [RaindropServer](../RaindropServer/CLAUDE.md) — a
decentralised, self-hosted chat server. Everything it says to a server is gRPC, defined in the sibling
[RaindropProto](../RaindropProto/CLAUDE.md) repo — read that file before changing anything in
`core/network/`; a change to a call or a message starts there, and is regenerated on both sides. What a
call *means* still has to track the server's CLAUDE.md exactly: this client has no other client to check
compatibility against.

## Commands

The Flutter SDK is on `PATH` (on the reference dev machine it lives at `~/sdks/flutter`).

```bash
flutter pub get
flutter analyze
flutter run -d macos      # or: -d windows, -d linux, -d ios, -d android, -d chrome (web is not a target)
flutter build macos --debug
```

The end-to-end encryption core is Rust, in `../RaindropCrypto` (kept out of this tree on purpose),
compiled into the app by `native/raindrop_crypto_builder` (cargokit). Building needs `rustup` on
`PATH` (Homebrew's is keg-only: `export PATH=/opt/homebrew/opt/rustup/bin:$PATH`), and CocoaPods for
iOS/macOS, because cargokit only supports pods; this plugin uses the Podfile while the others use
SPM. After changing `RaindropCrypto/crates/raindrop_crypto_ffi/src/api/`, regenerate the bindings
from this folder:

```bash
flutter_rust_bridge_codegen generate
```

The Dart package, the Rust crate and the codegen must all be flutter_rust_bridge **2.13.0**. See
`docs/crypto.md`.

`native/raindrop_camera_effects` is the other local plugin: it puts the camera effects' native
processor on a camera track flutter_webrtc is already capturing, through flutter_webrtc's own public
API. Unlike the cargokit one it is SPM on Apple and a plain `com.android.library` on Android, and it
builds no Rust of its own — the effects are in the same library the crypto core already ships. See
`docs/voice.md#camera-effects` and its own README.

The wire protocol lives in `../RaindropProto`. Its Dart is generated into
`lib/core/network/grpc/generated/` and **committed**, so nothing has to run before `flutter run`; after
any change to RaindropProto, regenerate it and commit the result (needs `brew install protobuf` and
`dart pub global activate protoc_plugin`, 25.x):

```bash
tool/gen_protos.sh
```

Integration tests against a live server (the real Rust core, the real server) are under
`test/integration/` and skip themselves unless `RAINDROP_TEST_SERVER=host:port` names a server with a
fresh database; see `docs/crypto.md#tests`.

Unit tests live under `test/` (`flutter test`) — pure logic only (models, merges, settings round-trips,
the payload encodings), plus one widget test for the layout editor's hit-testing (`test/core/layout/`)
and two that stand a fake platform up behind a channel or a binding
(`test/core/voice/call_session_host_test.dart`, `test/core/platform/app_lifecycle_test.dart`). Note that
`flutter test` reports `defaultTargetPlatform` as **android**, so anything that branches on the platform
has to say which one it means (`debugDefaultTargetPlatformOverride`) rather than relying on the default.
To check the network layer against a real server, run the server per its own CLAUDE.md
(`dotnet run --project ServerCli` from `RaindropServer/`, default `https://localhost:5001`) and run
`test/integration/transport_test.dart`, which needs no Rust core — the handshake and the pin, error
codes, and the event stream:

```bash
RAINDROP_TEST_SERVER=localhost:5001 flutter test test/integration/transport_test.dart
```

The web toolchain is not set up on the reference dev machine (`flutter doctor` will show Chrome
missing, and the web is not a target); macOS, iOS, Android, Windows and Linux build as-is. The
Android SDK and NDK are installed — cargokit cross-compiles the Rust core for Android itself, so a
`flutter build apk` needs no extra step, but the first one is slow for the same reason the first
desktop build is.
**Android is still proven in CI as well as locally** — `.github/workflows/ci.yml` builds `android` and
`ios` alongside the desktop targets, so a change to either platform's configuration is not verified
until that runs. An Android build needs a Rust target per ABI
(`rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android`). See
`docs/mobile.md`.

## Architecture

`lib/` splits into `core/` (reusable across every screen and platform) and `features/` (one folder
per screen area). A feature may depend on `core/`; `core/` never depends on a feature. This is what
makes the glass toggle and the network layer reusable — neither knows anything about servers rails or
chat views.

```
core/
  platform/   — the only place that branches on OS (RaindropPlatform, isApplePlatform, …),
                windows_processes (which process owns a window, over dart:ffi, for screen sharing), and
                appLifecycleProvider (whether the app is on screen — a phone suspends a backgrounded
                app outright, and calls have to be told)
  theme/      — AppThemeDefinition (JSON-backed theme model), AppTheme's ThemeData builder, the
                AppSurfaces color-role extension, and the catalog/active-theme controllers
  widgets/    — Panel (flat chrome surface), AdaptiveSwitch/AdaptiveActivityIndicator/showAdaptiveConfirm
  network/    — RaindropChannel (one TLS-pinned gRPC connection per server; turns failures into
                ApiException from the ErrorInfo reason), grpc/ (the code generated from RaindropProto,
                imported as `pb` through grpc/protocol.dart, and Wire's enum/time conversions),
                CertificatePinner, ServerTrust (identity-key pin, follows signed certificate changes),
                PinRegistry (the same pins, process-wide, for the voice engine's own sockets),
                EventStream (the bidirectional push stream, heartbeating), and one wrapper per service
                with its models: UsersApi, ChannelsApi, TextMessagesApi, MembersApi, RolesApi,
                VoiceApi, E2eeApi, AttachmentsApi
  voice/      — VoiceEngine (a call's microphone, camera and screen share, transport-agnostic) +
                LiveKitVoiceEngine, the only code that imports livekit_client / flutter_webrtc, and
                VoiceVideoView (draws a feed, which builds its own surface — so no widget outside
                core/voice/ ever names a track type), and CallSessionHost (keeping a call running
                while the app is off screen: a no-op except on Android)
  video/      — VoiceCameraEffect (what the user chose to do to their camera's background) and
                CameraEffects, the handle on the running native effects — the only file outside
                crypto/ that imports the generated bridge, because the effects ride in the same Rust
                library. No frame comes through Dart; the work is ../RaindropCrypto's raindrop_video
  crypto/     — CryptoEngine (end-to-end encryption, MLS) + MlsCryptoEngine over the generated Rust
                bridge in crypto/bridge/ (never import it elsewhere), AttachmentCipher (files, per-file
                keys) + RustAttachmentCipher, and CryptoStores (one SQLCipher store per server, its
                key in SecureStore)
  storage/    — AppPrefs (plain prefs), SecureStore (Keychain/Credential Manager/libsecret/Keystore),
                and AttachmentCache (encrypted attachments, and the temporary plaintext folder)
  layout/     — LayoutConfig (the main view's pane order/widths and slot buttons, JSON), LayoutStore
                (the local layout file), LayoutScope/LayoutRow/LayoutSlot, LayoutEditBarrier
  models/     — ServerProfile, the one cross-feature domain model
  router/     — go_router route table
features/
  onboarding/ — ConnectServerFlow + the connect/auth/reauth screens
  servers/    — ServersController (the local server list), ServerSession, serverEventsProvider +
                LiveSync (following the event stream), the per-server UUID→name lookup cache, the
                left-hand server rail
  channels/   — the server's channel list + the sidebar that renders it
  chat/       — ChatController (send, follow the event stream, page back), AttachmentTransfers
                (upload/open encrypted files) + the chat pane, its composer and attachment previews
  members/    — the roster with each member's presence + the right-hand member pane
  voice/      — the call, who is in each call, voice settings + per-member media, the voice view and
                its video tiles, the camera-and-effects sheet, the share picker and share tiles,
                member menu and call controls
  security/   — end-to-end encryption: DeviceSetupController (create/link/restore, register, bind
                the session), ChannelGroups (each channel's MLS group: join, catch up, Welcomes, key
                packages, roster reconcile, encrypt/decrypt), the setup pane that takes the chat pane
                when this device has no keys, the recovery-words dialog, Settings → Encryption
  settings/   — appearance (theme), the layout editor, voice & video, encryption, and
                connected-server management
  home/       — HomeShell/MainView, which assemble the above into the responsive shell, and
                layout/ — the main view's pane/slot/button ids, defaults, rules and button registry
```

State management is Riverpod (`flutter_riverpod`, `Notifier`/`AsyncNotifier`/`.family`), navigation is
`go_router`. Both are used plainly — no code generation — so there's nothing to run before `flutter
run` picks up a change.

### Theming

Chrome is flat and solid — the server rail, channel sidebar, message composer, and cards all wrap
their content in `Panel` (`core/widgets/panel.dart`) or the standard Material `Card`, colored from
`context.surfaces` (an `AppSurfaces` theme extension). There is no blur/translucency layer; visual
separation between panes comes entirely from `AppSurfaces`' tiered background colors (`rail` <
`sidebar` < `chat` in darkness), the same way a Discord-style client steps its panes.

A **theme** (`AppThemeDefinition`, `core/theme/theme_definition.dart`) is a name, a brightness, an
accent `seedColor` (everything else derives from this via `ColorScheme.fromSeed`), and the five
`AppSurfaces` colors — serialized to and from plain JSON (`{id, name, brightness, seedColor,
surfaces: {...}}`, colors as `"#RRGGBB"` hex). The app ships exactly two, `assets/themes/light.json`
and `assets/themes/dark.json`, loaded once at startup (`loadBuiltInThemes()`) and handed in via
`builtInThemesProvider` — the same "load before `runApp`, then override a provider" pattern
`AppPrefs`/`SharedPreferences` uses. Retheming either shipped theme, or adding a third bundled one, is
a matter of editing/adding a JSON file and listing it in `pubspec.yaml`'s `assets:`, not touching Dart.

Users can create their own themes too: `ThemeEditorScreen` (`features/settings/screens/
theme_editor_screen.dart`) is a color-by-hex-field form that saves through `ThemeCatalogController`
(`core/theme/theme_controller.dart`), which persists custom themes as a JSON array in `AppPrefs`
(`customThemesJson` — plain `SharedPreferences`, not a file on disk, since that's the storage layer
every other small piece of local app state already goes through). `themeCatalogProvider` is the
built-in-plus-custom list the Settings screen's theme selector renders; `activeThemeIdProvider` is
which one is picked (`kSystemThemeId` is the "match OS" pseudo-entry, resolved to the built-in
`light`/`dark` theme by `resolveActiveTheme()` using the platform's live brightness). Editing a
built-in theme forks it into a new custom one rather than mutating the shipped JSON in place; deleting
a custom theme that's currently active falls back to `kSystemThemeId`.

### Layout

Full detail: [`docs/layout.md`](docs/layout.md). The wide main view is arranged by a user-editable
`LayoutConfig` (`core/layout/`): panes in order with widths, and **slots** (toolbars inside panes —
`rail.footer`, `user.trailing`, `topBar.trailing`) listing button ids. It is saved to
`<app support>/layout.json` — a file, not `AppPrefs`, so it can be exported and imported — and applies
to every server. The ids, defaults, rules and the button registry live in `features/home/layout/`;
`core/` knows them only as open strings and keeps unknown ones. Every layout goes through
`LayoutConfig.normalize` (load, import, each edit, save). Rail, channel list and chat are required;
Settings must stay in some slot. The editor (Settings → Customize layout, `/settings/layout`) renders
the real `MainView` over a draft, made inert by `LayoutEditBarrier` except over slots. A new toolbar
button is an entry in `mainLayoutButtons`, not a widget hard-coded into a pane.

### Native feel per platform

Nothing here builds separate UI trees per OS. Instead:

- `core/platform/platform_info.dart` is the *only* file allowed to branch on `Platform`/
  `defaultTargetPlatform`. Everywhere else asks it a question (`isApplePlatform`, `isDesktopPlatform`)
  instead of re-deriving the check.
- `core/widgets/adaptive.dart` swaps in Cupertino controls (switches, alert dialogs, activity
  indicators) on iOS/macOS and Material ones elsewhere, for the handful of widgets Flutter doesn't
  already adapt on its own.
- Page-transition style and scroll physics (bouncing vs. clamping) come for free from Flutter's
  default `MaterialApp` behavior per platform — nothing had to be written for those.
- The shell (`features/home/screens/home_shell.dart`) is responsive by width, not by platform: a
  `LayoutBuilder` collapses the four-pane desktop layout into a single pane behind a drawer under
  680px, which is what makes phones and small windows usable without a separate mobile codebase.
- What a responsive layout *cannot* cover — a phone stopping a backgrounded app, and having two
  speakers instead of a device picker — sits behind its own seam (`CallSessionHost`,
  `appLifecycleProvider`, `VoiceEngine.setSpeakerphone`), each inert off the platform that needs it.
  See `docs/mobile.md`.

### Connecting to a server

Raindrop has no directory server — a client's only way to find a server is being told its address.
`ConnectServerFlow` (`features/onboarding/controllers/connect_server_flow.dart`) drives the whole
lifecycle:

1. Generate a GUID client-side (`Uuid().v4()`). This *is* the account identity the server will know
   the client by — see `RaindropServer/CLAUDE.md`'s "client holds a separate GUID per server" — and it
   doubles as this client's local storage key (`ServerProfile.id`), so there's no second synthetic id
   to keep in sync with it.
2. `ServerService.GetServerInfo` to confirm the server is reachable and see its capabilities; this is
   also what triggers the TLS handshake `CertificatePinner` observes.
3. `UserService.GetUserStatus` with that GUID. On a real first connection this always comes back
   `unregistered` — the `active`/`left_preserved` branches in `ServerAuthScreen` exist for GUID re-import,
   not the common path.
4. Register, log in, or rejoin. On success, `ConnectServerFlow.persist` pins the fingerprint observed
   in step 2 (only if nothing was pinned yet — trust-on-first-use, same model as SSH host keys), saves
   the session token, and registers the server with `ServersController`.

`ServerSessionController` (`features/servers/controllers/session_controller.dart`) resolves the
*current* session for an already-connected server on cold start: read the token from `SecureStore`,
call `UserService.GetMe` to confirm it's still valid, and fall back to `ReauthPrompt` (password only — the
GUID and pin are already on file) if it isn't. A session's token, once obtained, lives only in
`SecureStore`; `AppPrefs` only ever holds the non-secret server list (host/port/nickname) and UI
settings.

**Leaving is the server rail's right-click menu** (`features/servers/widgets/`): "Leave server" asks
for the password and whether to erase the account (`UserService.LeaveServer`, `preserveData`
inverted), hangs up a call on that server, then forgets the server locally; "Remove from this device"
is the local-only half, and the only one available while signed out. The rail also carries the
settings button by default, since it is the one pane shown for every server signed in or not.

Alongside the fingerprint, the client pins the server's **identity key** (`core/network/server_trust.dart`).
When a pinned certificate stops matching, session restore follows the change only if that pinned key
signed the new certificate; otherwise the mismatch stands.

`core/network/tls_pinning.dart` explains why pinning is implemented as the gRPC channel's
`onBadCertificate` handler (and `HttpClient.badCertificateCallback` for LiveKit's sockets): it only fires
when the platform's default trust check *fails*, which is exactly the self-signed-certificate case the
server defaults to. A pin refusal and an unreachable server both surface from gRPC as a failure to
connect; the pinner's `rejected` flag is what makes the first `certificate_mismatch`. A CA-issued certificate validates
normally and never reaches this code — matching the server's own documented trust model.

### Messages

Text channels are real: `ChannelsApi` wraps `ChannelService`, and `TextMessagesApi` wraps
`TextChannelService` (`SendEncryptedMessage`, `GetHistory`, `DeleteMessage`, `ReportMessage`). `ChatController`
(`features/chat/controllers/chat_controller.dart`) owns one channel's timeline, keyed by a
`(serverId, channelId)` pair — the same client can be signed into several servers at once, and
channel ids are only unique within one.

**Receiving is pushed.** Sending is ordinary unary calls; everything that changes on the server — from
this client, its other devices, or any other member — arrives over the event stream
(`EventService.Connect`, a bidirectional gRPC stream; see `docs/live-updates.md` and the server's
`docs/events.md`). `EventStream` (`core/network/`) keeps one reconnecting stream per signed-in server on
that server's `RaindropChannel`, sends a `Heartbeat` every `ready.heartbeat_interval` (that is what keeps
this member online in everybody's roster), and `resubscribe()`s — asking for a fresh `ready` — when the
app returns to the foreground; `serverEventsProvider(serverId)` owns it for the life of the session; and
each controller follows it through `LiveSync` (`features/servers/controllers/live_sync.dart`), which
hands it events, asks it to **re-read after every `ready`** (the server replays nothing, so that is how a
reconnect catches up), and polls only while the stream is down. A `ServerEvent` wraps the typed
`pb.ServerEvent`; its `type` is the server's event name (`message.created`, …) derived from the `oneof`
case, and `userId`/`channelId` are read the same way, so a feature filters first and then reads its
case (`event.proto.messageCreated`) with the wrapper's `fromProto`. `ChatController` merges
`message.created`/`message.deleted` on id (a deletion is a tombstone in place); its fallback poll is
three seconds. The provider is `autoDispose` so leaving a channel drops its subscription.

Two rules for anything new that follows the stream: create the `LiveSync` *before* the first fetch
and buffer events that arrive during it (`_early`), and reset per-build fields at the top of `build` —
Riverpod reuses the notifier instance on rebuild. A stream ended as `session_ended` (or refused as
`invalid_session`, e.g. after a server restart) invalidates `serverSessionProvider`, which is what routes
the shell to `ReauthPrompt`.

**Messages are end-to-end encrypted** when the server offers it (`e2ee.delivery.v1`) and this device
is set up: `ChatController` encrypts through `ChannelGroups` (`features/security/`) and sends it with
`SendEncryptedMessage`; received and paged messages are decrypted (or read from the local encrypted cache) in
`_decode`, and each `ChatMessage` carries a `MessageSecurity` — `encrypted`, `undecryptable` (sent
before this device joined; shown with a lock), or `plaintext` (pre-encryption; open-lock marker). See
`docs/messages-chat.md#end-to-end-encryption`.

**Sending is optimistic.** A message appears immediately with a local id, and is replaced by the
server's copy — real id and timestamp — when the send returns; a merge on id means an event or
re-read that already picked it up cannot leave it showing twice. The server pushes our own message
back too, sometimes before the send returns; that echo retires the matching pending copy. A failed
send stays in the timeline marked `MessageStatus.failed`, with retry and discard, rather than throwing
away what was typed.

Two server rules the client has to honour rather than work around:

- A message carries its author's **UUID**, never a name. `userLookupProvider`
  (`features/servers/controllers/user_lookup.dart`) resolves it through `UserService.LookupUser`,
  using Riverpod's per-argument caching as the cache: one request per distinct author, however many
  messages they wrote.
- A **deleted message still arrives**, with null content and `deleted` set. It is rendered as
  "message deleted" in place; dropping it would misrepresent the conversation and break the paging
  cursor that points at it.

**Deleting a message** (`ChatController.delete`) is offered by `canDeleteMessage` (`features/chat/models/
message.dart`): **your own message always** — no permission is consulted — and somebody else's only with
`manage_messages` (`Channel.canManageMessages`). Not optimistic; the server's tombstone is merged in, and
`mergeMessages` never lets a non-deleted copy overwrite a tombstone. Desktop shows a hover trash button, touch a
long-press sheet (message text is `SelectableText` on desktop only, since selecting uses the same gestures). The
confirm dialog says the server owner keeps a copy — the server archives deleted text for its owner.

**Channels are managed from the sidebar.** `ChannelsController` has `create`/`rename`/`delete` (the echoed
`channel.*` event merges on id). Rename/delete are per-channel permissions (`Channel.canRename`/`canDelete`);
`create_channels` is server-wide, so it comes from `serverPermissionsProvider` (`RoleService.GetMyRoles`, re-read on
role events). The "+" and the per-channel menu (hover "…"/right-click on desktop, long-press on touch) appear
only when allowed; `channel_name_dialog.dart` pre-checks names with a copy of the server's policy and shows
server errors such as `channel_name_taken` inline.

History pages backwards through the server's opaque cursor — pass `nextCursor` back untouched, never
parse it (`next_cursor` on the wire; absent at the beginning of the channel). The chat pane exposes that as a "Load earlier messages" row at the top of the list.

**Files** ([`docs/attachments.md`](docs/attachments.md)) are end-to-end encrypted: each is encrypted
under its own key by the Rust core (`AttachmentCipher`), streamed up (`AttachmentsApi.upload`: one
`Upload` client stream from the server's `received_size`, in frames of its `frame_bytes`, resumed from
`GetUploadStatus` after a break), and described — key, name,
type, hash, a sender-made thumbnail — inside a `files` message, attested under v2. The composer's
paperclip and desktop drag-and-drop check every file against the server's `GetAttachmentPolicy`
first; it shows only with `attachments.v1`, `attach_files` in the channel, and encryption on this
device. Received files preview inline (image, video and audio through `media_kit`) only when the
server's `preview.extensions` lists them, `AttachmentPreviewRegistry` knows them (the plugin seam), and
the extension the sender declared to the server matches the name in the message; everything else is a
file card that saves, and nothing received is ever opened by the app. Decrypted files live in a temporary
folder emptied at startup and exit.

### Members and presence

`MembersApi` wraps `MemberService.ListMembers`: every active member with a `presence` of `online` or
`offline` (the enum `raindrop.v1.Presence` on the wire, turned back into the name by `Wire.presence`). `MembersController` reads it once and then follows `member.joined`/`.renamed`/`.left`/
`.presence` events (presence is a state, applied as "set"), re-reading after every reconnect and
polling every fifteen seconds only while the stream is down. It is `autoDispose`, so the pane stops
following when it is hidden (which it is below 1000px unless toggled on). `ChannelsController`
follows `channel.*` events the same way and re-reads its list on any role event, since a role change
can change what this account sees.

`PresenceStatus` (`features/members/models/member.dart`) is the enum the UI works in, parsed from the
wire name rather than from an index. It is **declared in the order the roster shows them**, and
`groupByPresence` sorts on that declaration order and then on username, lower-cased so `Zoe` sorts
next to `alice` instead of after every lower-cased name. Adding a status — `idle`, `doNotDisturb` —
means inserting a value in its rightful place here and a matching one on the server; neither side
persists the numbers, so there is nothing to migrate. A wire name this build has never heard of parses
to `offline`, the one bucket that claims nothing about somebody.

The server already returns the list sorted the same way, but the pane sorts again for itself: it has
to group under headings regardless, and a list that merely arrived in the right order is one refactor
away from arriving in the wrong one. Only the `online` status has a colour of its own in the theme
(`AppSurfaces.onlineIndicator`); everything else borrows a muted foreground rather than adding a
colour every theme JSON would have to define.

Presence comes from the server's event streams: a member is online while their client has its stream
open and heartbeating, so a client killed rather than closed reads as offline about a minute later, and
everybody reads as offline after a server restart until their clients reconnect. See the server's own
CLAUDE.md.

### Voice

Full detail: [`docs/voice.md`](docs/voice.md). The server decides who may join, speak, show their
camera and moderate; the media goes over the transport it names on join (`livekit`), behind
`core/voice/VoiceEngine`, so the rest of the app never imports the media library.

- **One call at a time, across servers**: `voiceCallProvider` (global, kept alive). It follows the
  session with `ref.listen`, not `watch` — renaming a server rebuilds its session, and a watch would end
  the call. It never auto-rejoins after being replaced by another device, removed, or the call ending;
  it ends with a `notice` the shell shows once.
- **Signalling goes through the server this client already pins** (`/api/channels/voice/signal`, relayed
  to LiveKit) — the one connection to the server that is not gRPC, because it is LiveKit's own
  WebSocket protocol; joining, leaving and mute are `VoiceService` calls. LiveKit's SDK opens its own sockets, so the pins are also installed process-wide:
  `PinRegistry` + `PinnedHttpOverrides` as `HttpOverrides.global` in `main.dart`, registered by
  `ServerSessionController` (and on `adopt`). LiveKit's own pinning option cannot trust a self-signed
  certificate — it checks chain and hostname first.
- **Mute/deafen are persisted settings** (`voiceSettingsProvider`), not call state: deafen mutes,
  undeafen restores the mic as it was, unmute while deafened undeafens. **Per-member volume, local
  mute and a hidden camera** (`memberAudioProvider` → `MemberMedia`, keyed `serverId/userId`) are
  local only. Each remote member plays at `effectiveVolume` = own × output volume, capped at 2.0
  (libwebrtc source gain: 1 = as sent), 0 while deafened or locally muted.
- **The camera is call state, not a setting.** You cannot pre-arm a camera, so what is remembered is
  only *which* camera and *which* effect. Turning it on opens the camera-and-effects sheet first
  (a live preview; nothing is published while it is open), and then runs a handshake: tell the server,
  **wait for the media server's grant**, then publish — because a call token names the microphone only
  until the server adds the camera. A grant that never comes takes the claim back, so the roster never
  shows a camera nobody can see. Turning it off reverses the order, so the grant is never withdrawn
  from under a live track.
- **Screen sharing** (`voice.screen.v1`): a screen or a window, desktop only, with the camera's
  handshake (`startScreenShare`). **The 1080p cap is ours to enforce** — livekit_client sizes a desktop
  share from what it asked for, not what it got — so `_ScreenSizeGuard` reads the captured size from
  the sender's stats and scales every layer by `screenShareScale`. A screen never carries sound; a
  window's sound only on Windows 11, through flutter_webrtc's process-tree loopback, refused for any
  window whose tree contains Raindrop (`windowAudioUnavailableReason`). **Nobody's share is received
  until it is watched** (`disable()` on publish): a card with **Watch**, then the large stage. The
  picker's "Also share this window's sound" checkbox is the sharer's consent — unticked every time.
  Adaptive stream and dynacast are on, which is why the feed list never reads `publication.enabled`.
  See `docs/voice.md#screen-sharing`.
- **Hiding somebody's camera really stops the stream** (`publication.disable()`, not a hidden widget),
  saving the bandwidth as well as the screen space, and it is re-applied on every republish so it does
  not leak when they turn their camera off and on. `unsubscribe()` is kept for the untrusted case.
- **Camera effects run on macOS, iOS and Android**, and nothing is forked to make them: flutter_webrtc's
  per-frame hook is already public natively (`addProcessing:` / `addProcessor`) and only its Dart layer
  never uses it, so `native/raindrop_camera_effects` is a small plugin of ours that reaches it. Frames
  never come through Dart — `core/video/camera_effects_engine.dart` hands the platform a Rust handle and
  a function address, and the capture thread does the rest. The effects themselves are
  `../RaindropCrypto`'s `raindrop_video`, whose segmentation model is committed, so effects are on by
  default on those three. **A build with no model offers no effect at all** rather than a wrong one —
  that is `cameraEffectsAvailable`, the platform answer `canUseCameraEffects` plus what the native side
  says it has. Windows and Linux have no processor chain to insert into, and are still to do.
- **Calls are end-to-end encrypted** on a server with `e2ee.voice.v1`: the media key comes from the
  voice channel's MLS group (`ChannelGroups.mediaKey`, before joining — no key, no join), LiveKit's
  frame cryptor uses it (`VoiceEngine.connect(mediaKey:)`, `setMediaKey` on every epoch change), the
  lowest member id in the call rotates it every 10 minutes, unencrypted or undecryptable audio is kept
  silent, and `VoiceConnectionBar` shows a lock. See `docs/voice.md#end-to-end-encrypted-calls`.
- **"Mute for everyone"** needs server-wide `mute_members` (`serverPermissionsProvider`), and is
  enforced by the server; it arrives back as `voice.state`.
- `voiceRosterProvider(serverId)` follows `voice.state` / `voice.left` / `channel.deleted` and drives
  the sidebar's per-channel participant list and the voice view. Selecting a voice channel opens the
  view; joining is its button.
- **Calls survive the app leaving the screen on a phone**, and a call the network drops is rejoined
  (five tries over ~30s) rather than ended. The two platforms want opposite things for the first —
  iOS a background mode in `Info.plist`, Android a `microphone` foreground service — so both go
  through `core/voice/CallSessionHost`, and `InactiveCallSessionHost` covers everywhere that needs
  nothing. See `docs/mobile.md`.
- **Hanging up lets go of every device at once.** The microphone, camera and share stop immediately,
  without `Room.disconnect()`, which waits 10 s for an acknowledgement before stopping the tracks.
  **Quitting the app leaves the call first** (`leaveNow`, bounded to 1.5 s), and the server drops a
  crashed client after 5 s without a signalling connection. Watchers forget a share when its sharer
  leaves the call, and the full view closes itself. See `docs/voice.md`.

### What's still missing

- Push-to-talk, **camera effects on Windows and Linux** (they run on macOS, iOS and Android), sharing
  a screen from a phone, a window's sound on macOS and Linux, microphone gain; changing your username or
  password from the app; any role-editing or report-moderation UI.
- **Notifications**, including for messages that arrive while the app is closed. Raindrop is self-hosted
  with no push infrastructure; `docs/roadmap.md` lays out what closing that would cost.

The full, maintained inventory is [`docs/roadmap.md`](docs/roadmap.md) — update it in the same change
that closes one of these.

### Wire format

Protobuf over gRPC, nothing else (see `docs/wire-format.md` and RaindropProto's conventions): UUIDs as
lower-case strings, `Timestamp`s, crypto blobs as `bytes`, open sets (permissions, channel types, leave
reasons, capabilities) as strings, closed sets as enums that `Wire` turns back into names, and refusals
as gRPC statuses whose `ErrorInfo.reason` becomes `ApiException.code`. There is no JSON on the wire and
no `dio`.

The plaintext *inside* an end-to-end encrypted message (`core/crypto/message_payload.dart`) is protobuf
too — version byte `0x02`, then `raindrop.v1.MessagePayload`. Version 1 was MessagePack and is still
read (its first byte is a map marker, never `0x02`), so `msgpack_dart` stays for that alone. The
attestation bytes are built from fields, not from either encoding, so reports verify the same.
