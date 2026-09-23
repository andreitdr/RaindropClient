# Network layer

Folder: [`lib/core/network/`](../lib/core/network/). This is `core/`, so it knows nothing about
servers rails, chat views, or any other feature — see
[Architecture overview](architecture-overview.md).

## `ApiClient` — the transport

[`api_client.dart`](../lib/core/network/api_client.dart) is a thin HTTP client bound to **one**
Raindrop server, built on `dio`. It knows nothing about users, sessions, or channels — that lives in
the per-domain wrappers below. Kept generic on purpose, so a future domain (voice signaling) reuses the
same pinning and error handling instead of re-deriving it.

`ApiClient.forServer({host, port, pinnedFingerprint})`:

- Base URL is always `https://$host:$port` — Raindrop is TLS-only (see the server's
  [Transport security doc](../../RaindropServer/docs/transport-security.md)).
- Sends `Content-Type`/`Accept: application/json` unconditionally today — see [Wire format](wire-format.md).
- `validateStatus: (_) => true` — Dio is told never to throw on a non-2xx status, because the client
  parses the server's `{error, message}` body itself, for every status code, rather than working
  around Dio's own exception for it.
- Wires a `CertificatePinner` (below) into the platform `HttpClient`'s `badCertificateCallback`.

`.get(path, {token})` / `.post(path, {body, token})` both funnel through a private `_send`, which:

- adds `Authorization: Bearer $token` when a token is given,
- catches `DioException`, mapping a TLS `HandshakeException` to `ApiException.certificateMismatch()`
  and everything else to `ApiException.network(...)`,
- and turns any non-2xx response into `ApiException.fromResponseBody(status, data)`.

`.openWebSocket(path, {token})` opens the [event stream](live-updates.md) through the **same pinner and
the same bearer header**. It performs the upgrade by hand over an `HttpClient` (then
`WebSocket.fromUpgradedSocket`), so a refused upgrade keeps its status code and `{error, message}` body
and surfaces as the same `ApiException` a REST call would throw.

## `EventStream` — the push channel

[`event_stream.dart`](../lib/core/network/event_stream.dart) keeps one server's event stream open,
reconnecting with backoff, and exposes it as a `Stream<ServerEvent>` plus a status. Like the rest of
`core/network/` it depends only on `dart:io`, so it can be driven from a `dart run` script. See
[Live updates](live-updates.md).

## `CertificatePinner` — trust-on-first-use

[`tls_pinning.dart`](../lib/core/network/tls_pinning.dart) implements the same trust-on-first-use model
the server documents, SSH-host-key style:

- Computed as `sha256(cert.der)`, matching the server's own
  `Convert.ToHexString(SHA256.HashData(certificate.RawData))` — uppercase hex, no separators, compared
  case-insensitively after normalization.
- Wired in as `HttpClient.badCertificateCallback`, which **only fires when the platform's normal
  certificate validation fails** — exactly the case for the self-signed certificate a Raindrop server
  generates by default. A CA-issued certificate validates normally and this callback never runs for
  it, matching the server's own documented trust model (see
  [Transport security](../../RaindropServer/docs/transport-security.md)).
- `pinnedFingerprint == null` → accept-and-record (first connection). Otherwise → exact match required.
- `observedFingerprint` records whatever certificate was actually presented, as a side effect of the
  handshake, so the caller can pin it after a successful first connection — see
  [Connecting to a server](connecting-to-a-server.md).

## `ServerTrust` — following a certificate change

[`server_trust.dart`](../lib/core/network/server_trust.dart) pins the server's long-lived **identity
key** next to the fingerprint and uses it to follow a certificate the owner replaced on purpose (see
the server's [Transport security doc](../../RaindropServer/docs/transport-security.md#the-server-identity-key-changing-the-certificate-without-breaking-pins)).

- `verifyTlsBinding` checks the server's ECDSA P-256 signature (`r‖s`) over
  `"raindrop/tls-binding/v1\n" + fingerprint` with pointycastle. Malformed input returns `false`
  instead of throwing.
- `isConsistent(info, presented)` requires that the fingerprint `/api/server/info` advertises is the
  certificate the handshake presented, and that the identity key signed it. `ConnectServerFlow.probe`
  runs it on first contact.
- `pinIdentityIfMissing` pins the key over an already-pinned connection. That covers a first
  connection (`persist`) and clients upgraded from before identity keys existed (session restore).
- `followCertificateChange` runs when a pinned connection fails with `certificate_mismatch`. It makes
  one unauthenticated `/api/server/info` request over a probe connection that accepts any certificate,
  and re-pins only if the **pinned** identity key signed the certificate that probe was presented. With
  no identity key pinned, or with any check failing, the mismatch stands. `ServerSessionController`
  calls it, then retries the restore once.

## `ApiException`

[`api_exception.dart`](../lib/core/network/api_exception.dart) — thrown for every failure that reaches
API-calling code: a structured `{error, message}` body from the server, a transport failure, or a
client-side TLS pin mismatch. UI code branches on `.code` the same way the server's own error codes
are documented (`username_taken`, `invalid_credentials`, ...), plus two client-only codes:
`certificate_mismatch` and `network_error`.

## The per-domain API wrappers

Each wraps one server domain, and each is a Dart mirror of the matching C# contracts file — kept
literally in sync so a field rename on either side is caught at compile time on the Dart side (or, at
worst, a runtime `null` on a field that stopped arriving). JSON is camelCased by ASP.NET's default
serializer, so `UserId` on the wire is `userId` here — every `fromJson` reflects that.

| Wrapper | Wraps | Server contracts file | Doc |
|---|---|---|---|
| [`UsersApi`](../lib/core/network/users_api.dart) | `/api/server/info`, `/api/users/*` | [`Users/Contracts.cs`](../../RaindropServer/RaindropServer/Users/Contracts.cs) | [Connecting to a server](connecting-to-a-server.md), [Servers & sessions](servers-and-sessions.md) |
| [`ChannelsApi`](../lib/core/network/channels_api.dart) | `/api/channels`, `/api/channels/{create,rename,delete}` | [`Channels/ChannelContracts.cs`](../../RaindropServer/RaindropServer/Channels/ChannelContracts.cs) | [Channels](channels.md) |
| [`RolesApi`](../lib/core/network/roles_api.dart) | `/api/roles/me` (only) | [`Roles/RoleContracts.cs`](../../RaindropServer/RaindropServer/Roles/RoleContracts.cs) | [Channels](channels.md#creating-renaming-and-deleting) |
| [`MembersApi`](../lib/core/network/members_api.dart) | `/api/members` | [`Members/MemberContracts.cs`](../../RaindropServer/RaindropServer/Members/MemberContracts.cs) | [Members & presence](members-presence.md) |
| [`TextMessagesApi`](../lib/core/network/text_messages_api.dart) | `/api/channels/text/messages/{send,history,delete}` | [`Channels/Text/TextChannelContracts.cs`](../../RaindropServer/RaindropServer/Channels/Text/TextChannelContracts.cs) | [Messages & chat](messages-chat.md) |
| [`AttachmentsApi`](../lib/core/network/attachments_api.dart) | `/api/attachments/{policy,uploads/*,download}` — chunks go through `ApiClient.putBytes`, downloads through `ApiClient.downloadTo` | [`Attachments/AttachmentContracts.cs`](../../RaindropServer/RaindropServer/Attachments/AttachmentContracts.cs) | [Attachments](attachments.md) |
| [`VoiceApi`](../lib/core/network/voice_api.dart) | `/api/channels/voice`, `/api/channels/voice/{join,leave,state,mute}` | [`Channels/Voice/VoiceContracts.cs`](../../RaindropServer/RaindropServer/Channels/Voice/VoiceContracts.cs) | [Voice](voice.md) |

The audio of a call does not go through `ApiClient` at all: the voice engine (`core/voice/`) opens its
own sockets, which is why [`PinRegistry`](../lib/core/network/pin_registry.dart) and
`PinnedHttpOverrides` exist — a process-wide `HttpOverrides.global` that trusts exactly the fingerprints
this client has pinned, so LiveKit's signalling socket to the server's relay gets the same pin as
everything else. See [Voice](voice.md#how-a-call-is-carried).

Each wrapper's wire-shape classes deliberately carry a `Summary`/`Result`/`Page` suffix distinct from
the feature-layer UI model that's built from them (e.g. `MemberSummary` → `Member`,
`ChannelSummary` → `Channel`), the same split the server itself draws between a stored record and what
an endpoint returns.

One instance of each wrapper is built per connected server, as `late final` fields on
[`ServerSession`](servers-and-sessions.md#serversession-and-serversessioncontroller--the-live-connection) —
they all share that server's one `ApiClient`.

## Related

- [Connecting to a server](connecting-to-a-server.md) — where a client's GUID, the fingerprint, and the
  session token first come together.
- [Storage](storage.md) — where the pinned fingerprint and session token actually live.
- [Wire format](wire-format.md) — JSON today, MessagePack readiness.

## `E2eeApi`

[`e2ee_api.dart`](../lib/core/network/e2ee_api.dart) wraps `/api/e2ee/*`: registering and listing
devices, session challenge and binding, the sealed key backup, and the device-link relay. Byte fields
are base64 in JSON. It carries only public keys and opaque blobs; see [End-to-end encryption](crypto.md).
