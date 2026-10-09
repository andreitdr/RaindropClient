# Roadmap

What RaindropClient does today, and what it does not do yet. This file is the honest inventory for
the **app**; the other two projects keep their own, and a gap here is often a gap there too:

- [RaindropServer roadmap](../../RaindropServer/docs/roadmap.md) — the .NET backend.
- [RaindropCrypto roadmap](../../RaindropCrypto/docs/roadmap.md) — the Rust E2EE core.

**Keep this honest.** When something here ships, move it from *Not implemented yet* into
*Implemented* in the same change that ships it, and update the doc it points at.

## Implemented

| Area | What works | Doc |
|---|---|---|
| Platforms | macOS, Windows, Linux, iOS and Android, with per-platform adaptive chrome (web is not a target) | [Native feel per platform](native-feel-per-platform.md) |
| Servers | Several independent servers in one install, each with its own GUID, pinned certificate and session; add, switch, forget; cold-start session resolution and reauth | [Servers & sessions](servers-and-sessions.md) |
| Connecting | `ConnectServerFlow`: register, log in, rejoin a preserved account, trust-on-first-use fingerprint pinning, pinned-key changes surfaced | [Connecting to a server](connecting-to-a-server.md) |
| Channels | The channel list and sidebar, create/rename/delete, each gated on `yourPermissions` | [Channels](channels.md) |
| Messages | `ChatController`: history paging, optimistic send, deleting your own (or others' with the permission), tombstones, reporting an encrypted message | [Messages & chat](messages-chat.md) |
| Encryption | Device setup, first-device identity, linking by code or QR, recovery key, revocation, session binding; every channel's MLS group driven through the server's delivery service, so messages are **encrypted end to end** today | [Crypto](crypto.md), [Messages & chat](messages-chat.md#end-to-end-encryption) |
| Attachments | Picking, dropping, streamed encrypted upload with progress and resume, inline image/video/audio previews, thumbnails, saving, cache on disk | [Attachments](attachments.md) |
| Voice | Joining a call, mute, deafen, per-member volume and local mute, mute for everyone, the LiveKit engine over the server's relay with the same pinning, **media end-to-end encrypted** from the channel's MLS group | [Voice](voice.md) |
| Camera | Showing your camera in a call (grant before track, so a refusal never leaves a camera nobody can see), the camera-and-effects sheet with a live preview, camera and quality pickers, video tiles, and hiding one person's camera locally — which really stops the stream | [Voice](voice.md#camera) |
| Camera effects | Background blur and background replacement, applied to the frames in place on macOS, iOS and Android, with no fork of the media library and no frame ever reaching Dart | [Voice](voice.md#camera-effects) |
| Members | The roster pane, presence grouping, pushed presence updates | [Members & presence](members-presence.md) |
| Live updates | `EventStream` over the server's bidirectional gRPC stream with heartbeats and resubscribe on resume, `LiveSync` merging by id, reconnect with backoff and fallback polling | [Live updates](live-updates.md) |
| Layout | A user-arranged main view: pane order, widths, buttons in slots, hiding, saved to a local layout file, edited in a layout editor | [Layout](layout.md) |
| Theming | Two built-in themes, custom themes from asset/JSON definitions, a theme editor | [Theming](theming.md) |
| Settings | Theme, layout, voice & video (including camera and effects), encryption (devices, linking, new recovery key), connected servers | [Settings](settings.md) |
| Network | gRPC over one pinned connection per server (`RaindropChannel`), code generated from RaindropProto, per-service API wrappers | [Network layer](network-layer.md) |
| Storage | `AppPrefs` for preferences, `SecureStore` for tokens and store keys, the encrypted crypto store per server | [Storage](storage.md) |
| CI | Build on Linux/macOS/Windows and `flutter analyze` + `flutter test` on every push to `main`; desktop installers on a version tag | [CI & releases](ci-and-releases.md) |

## Not implemented yet

### Voice
- **Background audio on phones.** iOS has no background audio mode set and Android has no microphone
  foreground service, so a call stops being heard once the app is backgrounded.
- **Rejoining automatically after a dropped connection.** LiveKit's own reconnect is handled and shown
  as `reconnecting`, but a connection that is really gone ends the call with a notice; you join again.
- **Push-to-talk.**
- **Camera effects on Windows and Linux.** They run on macOS, iOS and Android
  ([Voice](voice.md#camera-effects)); those two have no chain between the capturer and the video
  source to put a processor into, so `canUseCameraEffects` is false there and the sheet says so. The
  effects themselves are already built and tested for every target in
  [RaindropCrypto](../../RaindropCrypto/docs/video-effects.md).
- **Screen sharing.** The camera widened the call token's `canPublishSources`; widening it again to
  the screen is the change, and the camera's handshake and cap are there to copy.
  [Server roadmap](../../RaindropServer/docs/roadmap.md#voice)
- **Microphone volume.** The voice library has no input gain on desktop; automatic gain control stands
  in for it.

### Account and moderation UI
- **Changing your username or password.** `UsersApi.changeUsername` and `changePassword` are wrapped
  and tested, but no screen calls them. [Network layer](network-layer.md)
- **Role and permission editing.** `RolesApi` only reads the caller's own roles; the server's full
  role API (create, update, assign, the permission catalogue) has no UI, so roles are granted from the
  server's console. [Server roles doc](../../RaindropServer/docs/roles-and-permissions.md)
- **A moderator view of reports.** The app can report an encrypted message; listing a channel's
  reports (`manage_messages`) is console-only today. [Messages & chat](messages-chat.md)

### Chat features
- **Message editing, reactions, threads, pinned messages, typing indicators, unread counts, mentions
  and search.** None of these exist on the server either; they are joint work.
  [Server roadmap](../../RaindropServer/docs/roadmap.md#chat)
- **Notifications.** No local or push notifications on any platform; the app only shows what is on
  screen while it is open.

### Protocol and packaging
- **Mobile release artefacts.** `release.yml` packages Linux (AppImage/deb/rpm), macOS (dmg) and
  Windows (zip); there is no signed `.apk`/`.aab` or TestFlight build.
  [CI & releases](ci-and-releases.md)
- **Code signing and notarisation.** CI switches macOS to ad-hoc signing, so released desktop builds
  are unsigned.

## Deliberately not planned

- **Web.** Flutter web is not a target: the app compiles a Rust crypto core, pins TLS certificates
  itself and keeps keys in the platform keystore, none of which a browser allows.
- **Talking to anything but a Raindrop server.** No bridges, no federation; each server is its own
  world, as the [server's architecture](../../RaindropServer/docs/architecture-overview.md#the-decentralisation-principle)
  requires.
- **Falling back to unencrypted messages where encryption is available.** When a server offers
  `e2ee.delivery.v1` and this device is set up, messages go through the group; plaintext is only for
  servers that explicitly allow it.

## Related

- [Voice](voice.md), [Wire format](wire-format.md), [Crypto](crypto.md) — the fuller context for the
  gaps above.
