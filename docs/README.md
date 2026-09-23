# RaindropClient documentation

RaindropClient is the cross-platform Flutter client for
[RaindropServer](../../RaindropServer/docs/README.md) — a decentralised, self-hosted chat server.
This client connects to one or more independent Raindrop servers, each identified by its own address
and pinned certificate, and each holding a separate identity (GUID) for this install.

This wiki documents the feature set as it stands today. Each file covers one area of the app; start
with [Architecture overview](architecture-overview.md) if you're new to the codebase.

## Contents

| Doc | Covers |
|---|---|
| [Architecture overview](architecture-overview.md) | `core/` vs. `features/` split, state management, folder layout |
| [Theming](theming.md) | `AppThemeDefinition`, the two built-in themes, custom themes, the theme editor |
| [Native feel per platform](native-feel-per-platform.md) | Platform branching, adaptive widgets, the responsive shell |
| [Connecting to a server](connecting-to-a-server.md) | `ConnectServerFlow`, registration/login/rejoin, fingerprint pinning |
| [Servers & sessions](servers-and-sessions.md) | The local server list, `ServerSession`, cold-start session resolution, reauth |
| [Channels](channels.md) | The channel list, creating/renaming/deleting channels, the sidebar |
| [Live updates](live-updates.md) | The event stream: `EventStream`, `serverEventsProvider`, `LiveSync`, reconnects and fallback polling |
| [Messages & chat](messages-chat.md) | `ChatController`, pushed messages, optimistic send, deleting a message, tombstones, history paging |
| [Attachments](attachments.md) | End-to-end encrypted files: picking and dropping, the server's rules, chunked uploads, thumbnails, previews (image/video/audio), saving, what stays on disk |
| [Members & presence](members-presence.md) | The roster pane, presence grouping, pushed presence |
| [Voice](voice.md) | Voice channels: joining a call, mute/deafen, per-member volume and mute, mute for everyone, the LiveKit engine and its pinning |
| [Layout](layout.md) | The customizable main view: pane order/widths, buttons in slots, the layout file, the layout editor |
| [Settings](settings.md) | Theme selection/editor, voice & audio, connected-server management |
| [Network layer](network-layer.md) | `ApiClient`, `CertificatePinner`, the per-domain API wrappers |
| [Storage](storage.md) | `AppPrefs` vs. `SecureStore` — what goes where and why |
| [End-to-end encryption](crypto.md) | The Rust MLS core in [`../RaindropCrypto`](../../RaindropCrypto/docs/README.md), the bridge and its build glue, `CryptoEngine`, the encrypted store |
| [Routing](routing.md) | The `go_router` route table |
| [Wire format](wire-format.md) | JSON today, MessagePack readiness |
| [Roadmap / what's missing](roadmap.md) | Known gaps against what the server already supports |

## Quick facts

- **Stack:** Flutter, targeting macOS, Windows, Linux, iOS and Android as real targets (web is not a
  target). State management is Riverpod (`Notifier`/`AsyncNotifier`/`.family`, no code generation);
  navigation is `go_router`.
- **Server relationship:** this client has no other client to check compatibility against — its
  `core/network/` contracts must track [RaindropServer's API](../../RaindropServer/docs/README.md)
  exactly.
- **What's implemented:** connecting to a server (register/login/rejoin), reading and posting to text
  channels, end-to-end encrypted file attachments with inline image/video/audio previews,
  creating/renaming/deleting channels and deleting messages (each gated on what the server says
  the account may do), viewing the member roster with presence, voice channels (group calls with mute,
  deafen, per-member volume and mute, and mute for everyone), live updates over the server's event stream
  (messages, deletions, channels, roster, presence and who is in which call arrive as they happen), theming
  (built-in + custom), a user-arranged main view (panes and buttons moved, resized and hidden in a
  layout editor, saved to a local file), per-platform adaptive chrome.
- **What's not implemented yet:** background voice on phones, MessagePack encoding. See [Roadmap](roadmap.md).

## Keeping this wiki current

**Update the relevant file(s) here whenever a feature changes or a new one is added** — a new screen,
a changed controller, a new provider, a new dependency, a change to how the client talks to the server.
Treat this as part of the change, not a follow-up: a docs folder that drifts from the code is worse
than no docs folder, because it actively misleads. When a change doesn't fit any existing file, add a
new one and link it from the table above. If a change affects the server's API contract, update the
matching [RaindropServer doc](../../RaindropServer/docs/README.md) too.
