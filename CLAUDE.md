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
decentralised, self-hosted chat server. Read that file when touching anything in `core/network/`;
this client's contracts must track that server's exactly, and it has no other client to check
compatibility against.

## Commands

The Flutter SDK lives at `/Volumes/SSD/SDK/flutter` and is not on this shell's `PATH`; prefix
commands with it or add it to `PATH` for the session:

```bash
export PATH="/Volumes/SSD/SDK/flutter/bin:$PATH"
```

```bash
flutter pub get
flutter analyze
flutter run -d macos      # or: -d windows, -d linux, -d ios, -d android, -d chrome (web is not a target)
flutter build macos --debug
```

Unit tests live under `test/` (`flutter test`) — pure logic only (models, merges, settings round-trips),
no widget tests yet. To sanity-check the network layer against a real server, run the
server per its own CLAUDE.md (`dotnet run --project ServerCli` from `RaindropServer/`, default
`https://localhost:5001`) and drive `core/network/api_client.dart` and the API wrappers beside it
(`users_api.dart`, `channels_api.dart`, `text_messages_api.dart`) from a scratch script — they depend
only on `dio`, `crypto`, and `dart:io`, not on Flutter, so `dart run` works without a device
attached.

Android and web toolchains are not set up on the reference dev machine (`flutter doctor` will show
Android SDK and Chrome missing); macOS, iOS, Windows, and Linux desktop targets build as-is.

## Architecture

`lib/` splits into `core/` (reusable across every screen and platform) and `features/` (one folder
per screen area). A feature may depend on `core/`; `core/` never depends on a feature. This is what
makes the glass toggle and the network layer reusable — neither knows anything about servers rails or
chat views.

```
core/
  platform/   — the only place that branches on OS (RaindropPlatform, isApplePlatform, …)
  theme/      — AppThemeDefinition (JSON-backed theme model), AppTheme's ThemeData builder, the
                AppSurfaces color-role extension, and the catalog/active-theme controllers
  widgets/    — Panel (flat chrome surface), AdaptiveSwitch/AdaptiveActivityIndicator/showAdaptiveConfirm
  network/    — ApiClient (TLS-pinned Dio wrapper, plus the pinned WebSocket upgrade),
                CertificatePinner, PinRegistry (the same pins, process-wide, for the voice engine's
                own sockets), EventStream (the server's push channel), and one wrapper per server
                domain with its DTOs: UsersApi, ChannelsApi, TextMessagesApi, MembersApi, RolesApi,
                VoiceApi
  voice/      — VoiceEngine (a call's audio, transport-agnostic) + LiveKitVoiceEngine, the only code
                that imports livekit_client / flutter_webrtc
  storage/    — AppPrefs (plain prefs) and SecureStore (Keychain/Credential Manager/libsecret/Keystore)
  models/     — ServerProfile, the one cross-feature domain model
  router/     — go_router route table
features/
  onboarding/ — ConnectServerFlow + the connect/auth/reauth screens
  servers/    — ServersController (the local server list), ServerSession, serverEventsProvider +
                LiveSync (following the event stream), the per-server UUID→name lookup cache, the
                left-hand server rail
  channels/   — the server's channel list + the sidebar that renders it
  chat/       — ChatController (send, follow the event stream, page back) + the chat pane
  members/    — the roster with each member's presence + the right-hand member pane
  voice/      — the call, who is in each call, voice settings + per-member audio, the voice view,
                member menu and call controls
  settings/   — appearance (theme), voice & audio, and connected-server management
  home/       — HomeShell, which assembles the above into the responsive shell
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

### Connecting to a server

Raindrop has no directory server — a client's only way to find a server is being told its address.
`ConnectServerFlow` (`features/onboarding/controllers/connect_server_flow.dart`) drives the whole
lifecycle:

1. Generate a GUID client-side (`Uuid().v4()`). This *is* the account identity the server will know
   the client by — see `RaindropServer/CLAUDE.md`'s "client holds a separate GUID per server" — and it
   doubles as this client's local storage key (`ServerProfile.id`), so there's no second synthetic id
   to keep in sync with it.
2. `GET /api/server/info` to confirm the server is reachable and see its wire formats; this is also
   what triggers the TLS handshake `CertificatePinner` observes.
3. `POST /api/users/status` with that GUID. On a real first connection this always comes back
   `unregistered` — the `active`/`left_preserved` branches in `ServerAuthScreen` exist for GUID re-import,
   not the common path.
4. Register, log in, or rejoin. On success, `ConnectServerFlow.persist` pins the fingerprint observed
   in step 2 (only if nothing was pinned yet — trust-on-first-use, same model as SSH host keys), saves
   the session token, and registers the server with `ServersController`.

`ServerSessionController` (`features/servers/controllers/session_controller.dart`) resolves the
*current* session for an already-connected server on cold start: read the token from `SecureStore`,
call `/api/users/me` to confirm it's still valid, and fall back to `ReauthPrompt` (password only — the
GUID and pin are already on file) if it isn't. A session's token, once obtained, lives only in
`SecureStore`; `AppPrefs` only ever holds the non-secret server list (host/port/nickname) and UI
settings.

`core/network/tls_pinning.dart` explains why pinning is implemented as an `HttpClient
.badCertificateCallback`: it only fires when the platform's default trust check *fails*, which is
exactly the self-signed-certificate case the server defaults to. A CA-issued certificate validates
normally and never reaches this code — matching the server's own documented trust model.

### Messages

Text channels are real: `ChannelsApi` fetches `GET /api/channels`, and `TextMessagesApi` wraps
`/api/channels/text/messages/{send,history}`. `ChatController`
(`features/chat/controllers/chat_controller.dart`) owns one channel's timeline, keyed by a
`(serverId, channelId)` pair — the same client can be signed into several servers at once, and
channel ids are only unique within one.

**Receiving is pushed.** Sending stays REST; everything that changes on the server — from this client,
its other devices, or any other member — arrives over the event stream (`GET /api/events`, see
`docs/live-updates.md` and the server's `docs/events.md`). `EventStream` (`core/network/`) keeps one
reconnecting, TLS-pinned WebSocket per signed-in server; `serverEventsProvider(serverId)` owns it for
the life of the session; and each controller follows it through `LiveSync`
(`features/servers/controllers/live_sync.dart`), which hands it events, asks it to **re-read after
every `ready`** (the server replays nothing, so that is how a reconnect catches up), and polls only
while the stream is down — which keeps the client working against a server without `/api/events`.
`ChatController` merges `message.created`/`message.deleted` on id (a deletion is a tombstone in place);
its fallback poll is three seconds. The provider is `autoDispose` so leaving a channel drops its
subscription.

Two rules for anything new that follows the stream: create the `LiveSync` *before* the first fetch
and buffer events that arrive during it (`_early`), and reset per-build fields at the top of `build` —
Riverpod reuses the notifier instance on rebuild. A `4401` close (session ended, e.g. after a server
restart) invalidates `serverSessionProvider`, which is what routes the shell to `ReauthPrompt`.

**Sending is optimistic.** A message appears immediately with a local id, and is replaced by the
server's copy — real id and timestamp — when the send returns; a merge on id means an event or
re-read that already picked it up cannot leave it showing twice. The server pushes our own message
back too, sometimes before the send returns; that echo retires the matching pending copy. A failed
send stays in the timeline marked `MessageStatus.failed`, with retry and discard, rather than throwing
away what was typed.

Two server rules the client has to honour rather than work around:

- A message carries its author's **UUID**, never a name. `userLookupProvider`
  (`features/servers/controllers/user_lookup.dart`) resolves it through `POST /api/users/lookup`,
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
`create_channels` is server-wide, so it comes from `serverPermissionsProvider` (`GET /api/roles/me`, re-read on
role events). The "+" and the per-channel menu (hover "…"/right-click on desktop, long-press on touch) appear
only when allowed; `channel_name_dialog.dart` pre-checks names with a copy of the server's policy and shows
server errors such as `channel_name_taken` inline.

History pages backwards through the server's opaque cursor — pass `nextCursor` back untouched, never
parse it. The chat pane exposes that as a "Load earlier messages" row at the top of the list.

### Members and presence

`MembersApi` fetches `GET /api/members`: every active member with a `presence` of `online` or
`offline`. `MembersController` reads it once and then follows `member.joined`/`.renamed`/`.left`/
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

Presence comes from the server's live sessions, so it is only as sharp as those are: everybody reads
as offline after a server restart, and a client killed rather than closed reads as online until its
session lapses. See the server's own CLAUDE.md for why, and for what would sharpen it.

### Voice

Full detail: [`docs/voice.md`](docs/voice.md). The server decides who may join, speak and moderate; the
audio goes over the transport it names on join (`livekit`), behind `core/voice/VoiceEngine`, so the rest
of the app never imports the media library.

- **One call at a time, across servers**: `voiceCallProvider` (global, kept alive). It follows the
  session with `ref.listen`, not `watch` — renaming a server rebuilds its session, and a watch would end
  the call. It never auto-rejoins after being replaced by another device, removed, or the call ending;
  it ends with a `notice` the shell shows once.
- **Signalling goes through the server this client already pins** (`/api/channels/voice/signal`, relayed
  to LiveKit). LiveKit's SDK opens its own sockets, so the pins are also installed process-wide:
  `PinRegistry` + `PinnedHttpOverrides` as `HttpOverrides.global` in `main.dart`, registered by
  `ServerSessionController` (and on `adopt`). LiveKit's own pinning option cannot trust a self-signed
  certificate — it checks chain and hostname first.
- **Mute/deafen are persisted settings** (`voiceSettingsProvider`), not call state: deafen mutes,
  undeafen restores the mic as it was, unmute while deafened undeafens. **Per-member volume and local
  mute** (`memberAudioProvider`, keyed `serverId/userId`) are local only. Each remote member plays at
  `effectiveVolume` = own × output volume, capped at 2.0 (libwebrtc source gain: 1 = as sent), 0 while
  deafened or locally muted.
- **"Mute for everyone"** needs server-wide `mute_members` (`serverPermissionsProvider`), and is
  enforced by the server; it arrives back as `voice.state`.
- `voiceRosterProvider(serverId)` follows `voice.state` / `voice.left` / `channel.deleted` and drives
  the sidebar's per-channel participant list and the voice view. Selecting a voice channel opens the
  view; joining is its button.

### What's still missing

- **Background voice on phones** (iOS background audio, Android microphone foreground service), and
  rejoining automatically after a dropped connection.

### Wire format

The server negotiates JSON or MessagePack via `Content-Type`/`Accept` and documents that MessagePack's
win only shows up on larger, more numeric payloads than user management (see its CLAUDE.md). This
client only speaks JSON for now (`ApiClient` sends `application/json` unconditionally) — add
MessagePack encoding (the `msgpack_dart` dependency is already in `pubspec.yaml`, unused) once chat or
voice metadata is the thing being fetched.
