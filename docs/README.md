# RaindropClient documentation

RaindropClient is the cross-platform Flutter client for
[RaindropServer](../../RaindropServer/docs/README.md) — a decentralised, self-hosted chat server.
This client connects to one or more independent Raindrop servers, each identified by its own address
and pinned certificate, and each holding a separate identity (GUID) for this install.

This wiki documents the feature set as it stands today. Each file covers one area of the app; start
with [Architecture overview](architecture-overview.md) if you're new to the codebase, and
[Roadmap](roadmap.md) for what is and is not built yet.

## The three Raindrop projects

Raindrop is three repositories, checked out side by side in one folder:

| Project | What it is | Its docs |
|---|---|---|
| **RaindropClient** (this one) | The Flutter app for macOS, Windows, Linux, iOS and Android | you are here |
| [RaindropServer](../../RaindropServer/docs/README.md) | The self-hosted .NET backend. This app is its only client, so `core/network/` must track its API exactly | [docs](../../RaindropServer/docs/README.md) |
| [RaindropCrypto](../../RaindropCrypto/docs/README.md) | The Rust end-to-end encryption core (MLS over OpenMLS). The app compiles it in and is its only caller | [docs](../../RaindropCrypto/docs/README.md) · [this app's side](crypto.md) |

The sibling checkouts are not optional: `native/raindrop_crypto_builder` builds
`../RaindropCrypto` during `flutter build`, so the app does not compile without it.

## Contents

| Doc | Covers |
|---|---|
| [Architecture overview](architecture-overview.md) | `core/` vs. `features/` split, state management, folder layout |
| [Theming](theming.md) | `AppThemeDefinition`, the two built-in themes, custom themes, the theme editor |
| [Native feel per platform](native-feel-per-platform.md) | Platform branching, adaptive widgets, the responsive shell |
| [Android and iOS](mobile.md) | What a phone needs that a desktop does not: background voice, resuming after suspension, rejoining a dropped call, the speaker, building and permissions |
| [Connecting to a server](connecting-to-a-server.md) | `ConnectServerFlow`, registration/login/rejoin, fingerprint pinning |
| [Servers & sessions](servers-and-sessions.md) | The local server list, `ServerSession`, cold-start session resolution, reauth |
| [Channels](channels.md) | The channel list, creating/renaming/deleting channels, the sidebar |
| [Live updates](live-updates.md) | The event stream: `EventStream`, `serverEventsProvider`, `LiveSync`, reconnects and fallback polling |
| [Messages & chat](messages-chat.md) | `ChatController`, pushed messages, optimistic send, deleting a message, tombstones, history paging |
| [Attachments](attachments.md) | End-to-end encrypted files: picking and dropping, the server's rules, streamed uploads, thumbnails, previews (image/video/audio), saving, what stays on disk |
| [Members & presence](members-presence.md) | The roster pane, presence grouping, pushed presence |
| [Voice](voice.md) | Voice channels: joining a call, mute/deafen, per-member volume and mute, mute for everyone, the LiveKit engine and its pinning |
| [Layout](layout.md) | The customizable main view: pane order/widths, buttons in slots, the layout file, the layout editor |
| [Settings](settings.md) | Theme selection/editor, the layout editor, voice & audio, encryption (devices, linking, recovery key), connected-server management |
| [Network layer](network-layer.md) | gRPC: `RaindropChannel`, the generated code and how to regenerate it, `ApiException`, `CertificatePinner`, the per-service API wrappers |
| [Storage](storage.md) | `AppPrefs` vs. `SecureStore` — what goes where and why |
| [End-to-end encryption](crypto.md) | The Rust MLS core in [`../RaindropCrypto`](../../RaindropCrypto/docs/README.md), the bridge and its build glue, `CryptoEngine`, the encrypted store |
| [Routing](routing.md) | The `go_router` route table |
| [Wire format](wire-format.md) | Protobuf over gRPC, and the protobuf payload inside encrypted messages (v1 MessagePack still read) |
| [CI & releases](ci-and-releases.md) | The GitHub Actions workflows, the two-repository checkout they need, and the desktop packaging |
| [Roadmap](roadmap.md) | Everything implemented today, everything that is not, and what is deliberately not planned |

## Quick facts

- **Stack:** Flutter, targeting macOS, Windows, Linux, iOS and Android as real targets (web is not a
  target). State management is Riverpod (`Notifier`/`AsyncNotifier`/`.family`, no code generation);
  navigation is `go_router`.
- **Server relationship:** everything this client says to a server is gRPC, defined in
  [RaindropProto](../../RaindropProto/README.md) and generated into `core/network/grpc/generated/` —
  the same files the server compiles, so the two cannot disagree about a field. What a call *means*
  still has to track [RaindropServer](../../RaindropServer/docs/README.md), which has no other client.
- **What's implemented:** connecting to a server (register/login/rejoin), reading and posting to text
  channels with **end-to-end encrypted messages**, end-to-end encrypted file attachments with inline
  image/video/audio previews, creating/renaming/deleting channels and deleting messages (each gated on
  what the server says the account may do), viewing the member roster with presence, voice channels
  (group calls with mute, deafen, per-member volume and mute, mute for everyone, and end-to-end
  encrypted media), live updates over the server's event stream (messages, deletions, channels, roster,
  presence and who is in which call arrive as they happen), device setup and linking for encryption,
  theming (built-in + custom), a user-arranged main view (panes and buttons moved, resized and hidden in
  a layout editor, saved to a local file), per-platform adaptive chrome, and phones as a full target
  (calls that survive switching apps, event streams re-read on the way back, a dropped call rejoined,
  and the earpiece/loudspeaker choice). See [Android and iOS](mobile.md).
- **End-to-end encryption is on by default** wherever the server offers it: this app drives each
  channel's MLS group through the server's delivery service, so text, files and call media are all
  encrypted for real. See [Crypto](crypto.md).
- **What's not implemented yet:** push-to-talk, camera effects on Windows and Linux, sharing a screen
  from a phone, changing your username or password from the app, any role-editing UI, and notifications. See
  [Roadmap](roadmap.md).

## Keeping this wiki current

**Update the relevant file(s) here whenever a feature changes or a new one is added** — a new screen,
a changed controller, a new provider, a new dependency, a change to how the client talks to the server.
Treat this as part of the change, not a follow-up: a docs folder that drifts from the code is worse
than no docs folder, because it actively misleads. When a change doesn't fit any existing file, add a
new one and link it from the table above. If a change affects the server's API contract, update the
matching [RaindropServer doc](../../RaindropServer/docs/README.md) too.

**[Roadmap](roadmap.md) is part of that.** Anything that moves between implemented and not goes there
in the same change, and a gap that crosses a project boundary is recorded in the other project's
roadmap too ([RaindropServer](../../RaindropServer/docs/roadmap.md) ·
[RaindropCrypto](../../RaindropCrypto/docs/roadmap.md)).
