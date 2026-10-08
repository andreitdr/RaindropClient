# Architecture overview

## `core/` vs. `features/`

`lib/` splits into `core/` (reusable across every screen and platform) and `features/` (one folder per
screen area). **A feature may depend on `core/`; `core/` never depends on a feature.** This one-way
rule is what makes things like the theming system and the network layer reusable — neither one knows
anything about server rails or chat views.

```
lib/
  app.dart, main.dart
  core/
    platform/   — the only place that branches on OS (RaindropPlatform, isApplePlatform, …)
    theme/      — AppThemeDefinition (JSON-backed theme model), AppTheme's ThemeData builder, the
                  AppSurfaces color-role extension, and the catalog/active-theme controllers
    widgets/    — Panel (flat chrome surface), AdaptiveSwitch/AdaptiveActivityIndicator/showAdaptiveConfirm
    network/    — RaindropChannel (one TLS-pinned gRPC connection per server), the code generated
                  from RaindropProto (grpc/generated/, through grpc/protocol.dart), CertificatePinner,
                  ServerTrust, PinRegistry (the same pins, process-wide, for the voice engine's own
                  sockets), EventStream, and one wrapper per service with its models: UsersApi,
                  ChannelsApi, TextMessagesApi, MembersApi, RolesApi, VoiceApi, E2eeApi, AttachmentsApi
    voice/      — VoiceEngine (a call's audio, transport-agnostic) and LiveKitVoiceEngine, the only
                  code that imports livekit_client / flutter_webrtc
    storage/    — AppPrefs (plain prefs) and SecureStore (Keychain/Credential Manager/libsecret/Keystore)
    layout/     — LayoutConfig (the main view's pane order/widths and slot buttons, as JSON),
                  LayoutStore (the layout file), LayoutScope/LayoutRow/LayoutSlot, and the editor's
                  LayoutEditBarrier — ids as open strings; see layout.md
    models/     — ServerProfile, the one cross-feature domain model
    router/     — go_router route table
  features/
    onboarding/ — ConnectServerFlow + the connect/auth/reauth screens
    servers/    — ServersController (the local server list), ServerSession, the per-server UUID→name
                  lookup cache, the left-hand server rail
    channels/   — the server's channel list + the sidebar that renders it
    chat/       — ChatController (send, follow the event stream, page back) + the chat pane
    members/    — the roster with each member's presence + the right-hand member pane
    voice/      — the call (voiceCallProvider), who is in each call (voiceRosterProvider), voice
                  settings and per-member audio, the voice view, member menu and call controls
    settings/   — appearance (theme), voice & audio, and connected-server management
    home/       — HomeShell, which assembles the above into the responsive shell
```

Each `features/<name>/` folder itself splits into `controllers/`, `models/`, `screens/` and/or
`widgets/` as needed — see the individual feature docs for each one's contents.

## State management

[Riverpod](https://riverpod.dev) (`flutter_riverpod`), used plainly: `Notifier`, `AsyncNotifier`, and
`.family`/`.autoDispose` variants, **no code generation**. There's nothing to run (`build_runner` or
otherwise) before `flutter run` picks up a change — every provider is a hand-written top-level
`final ... = NotifierProvider(...)` (or `AsyncNotifierProvider`, etc.) next to its controller class.

Two provider-scoping patterns recur throughout the codebase and are worth recognizing on sight:

- **`.family`** — a provider keyed by an argument, used whenever state exists per-server or
  per-channel: `serverSessionProvider(serverId)`, `chatProvider((serverId, channelId))`,
  `channelsProvider(serverId)`, `membersProvider(serverId)`.
- **`.autoDispose`** — used for anything that follows the event stream only while it is on screen
  (chat, members), so navigating away from a channel or hiding the member pane drops its subscription
  and any fallback poll, rather than leaking them. The stream itself (`serverEventsProvider`) is *not*
  auto-disposing: it stays open for the whole session. See [Live updates](live-updates.md).

## Load-before-`runApp` pattern

Two pieces of state are asynchronous but read synchronously everywhere else in the app:
`SharedPreferences` (`AppPrefs`, see [Storage](storage.md)) and the two bundled theme JSON files (see
[Theming](theming.md)). Both are loaded once in `main.dart` *before* `runApp`, then handed to the
widget tree by overriding a `Provider` (`appPrefsProvider`, `builtInThemesProvider`) that otherwise
throws `UnimplementedError` if read too early. This is the one initialization pattern to reach for any
time a new piece of state needs to exist before the first frame.

## Navigation

`go_router` (see [Routing](routing.md)). Routes are intentionally shallow — `/` alone decides whether
to show onboarding or the main shell, so nothing needs a redirect guard.

## Related

- [Theming](theming.md) and [Native feel per platform](native-feel-per-platform.md) — the two `core/`
  concerns most visible to a user.
- [Network layer](network-layer.md) and [Storage](storage.md) — the two `core/` concerns every feature
  builds on.
