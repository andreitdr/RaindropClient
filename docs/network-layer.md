# Network layer

Folder: [`lib/core/network/`](../lib/core/network/). This is `core/`, so it knows nothing about server
rails, chat views or any other feature; see [Architecture overview](architecture-overview.md).

Everything this client says to a server is **gRPC**: HTTP/2 inside TLS, protobuf messages, defined in
the sibling [RaindropProto](../../RaindropProto/README.md) repository (`raindrop.v1`). There is no REST
and no JSON on the wire. The one exception is a call's audio signalling, which is LiveKit's own
WebSocket relayed by the server (see [Voice](voice.md)).

## The generated code

[`lib/core/network/grpc/generated/`](../lib/core/network/grpc/generated/) holds the Dart that
`protoc` generates from RaindropProto: one client stub per service, and one class per message. It is
**committed**, so `flutter run` needs no generation step.

- After any change to RaindropProto, regenerate it with
  [`tool/gen_protos.sh`](../tool/gen_protos.sh) and commit the result.
- The script needs `protoc` and `dart pub global activate protoc_plugin` (25.x, which generates for
  the `protobuf` 6 runtime this app shares with `livekit_client`).
- The analyzer skips that folder.

Import it through [`grpc/protocol.dart`](../lib/core/network/grpc/protocol.dart), always prefixed
`as pb`. Several generated names (`Channel`, `Member`, `Session`, `Role`) are also names of this app's
own models.

The well-known types (`Timestamp`, `Duration`) come from `package:protobuf`, and the `google.rpc` error
details from `package:grpc`. Only Raindrop's own files are generated.

[`grpc/wire.dart`](../lib/core/network/grpc/wire.dart) holds the conversions every wrapper needs:
- Times to UTC `DateTime`.
- Bytes to `Uint8List`.
- The protocol's closed enums back to the **names** the app works with (`active`, `online`, `owner`,
  `file`, `uploading`, …).

The models and UI were written against names, and an enum value newer than this build still becomes a
name (`unknown`) that each feature falls back on.

## `RaindropChannel`: the transport

[`raindrop_channel.dart`](../lib/core/network/raindrop_channel.dart) is one gRPC connection to
**one** server. `RaindropChannel.forServer({host, port, pinnedFingerprint})` builds a
`ClientChannel` with `ChannelCredentials.secure(onBadCertificate: pinner.accepts)`: TLS only, with the
pin below. It knows nothing about users, sessions or channels; the per-domain wrappers build their
generated clients on its `channel`.

- `call(send, {token, timeout})` runs one unary call:
  - It attaches the session token as `authorization: Bearer <token>` metadata. That is the only thing
    that ever goes in metadata, and nothing goes in a URL.
  - It sets a deadline (20 s by default; none for streams).
  - It turns any failure into an `ApiException` (below).
- `stream(s)` does the same for a stream's failure.
- `options({token, timeout})` builds the call options for a streaming call.

## `ApiException`

[`api_exception.dart`](../lib/core/network/api_exception.dart) is what every failure becomes. UI code
branches on `.code` and shows `.message`.

- **A refusal from the server.** It is a gRPC status whose `grpc-status-details-bin` trailer holds a
  `google.rpc.ErrorInfo` with domain `raindrop`. Its `reason` becomes `.code` (`username_taken`,
  `invalid_credentials`, `stale_epoch`, …; every one is listed in RaindropProto's
  [errors doc](../../RaindropProto/docs/errors.md)), and the status message becomes `.message`, written
  for people.
  - `ApiException.reasonOf` reads the `ErrorInfo` by type name and field number. Package:grpc decodes
    the trailer with its own copy of `error_details.proto`, which it does not export.
- **A failure with no reason** is the transport's own. Either the pinner refused the certificate
  (`certificate_mismatch`; the pinner's `rejected` flag tells it apart, since gRPC reports both as a
  failure to connect), or the server did not answer (`network_error`).
- `.statusCode` is the gRPC status code, or 0 for a failure that never reached the server. It is for
  logs; `.code` is the contract. One exception: a server without a service at all answers
  `unimplemented`, which the voice roster takes as "no voice here".

## `EventStream`: the push channel

[`event_stream.dart`](../lib/core/network/event_stream.dart) keeps one server's bidirectional
`EventService.Connect` stream open, heartbeating and reconnecting with backoff. It exposes the stream
as a `Stream<ServerEvent>` plus a status. `ServerEvent` wraps the typed `pb.ServerEvent`, and answers
`type`, `userId` and `channelId` from whichever `oneof` case it carries, so a feature filters first
and reads the case it wants second. See [Live updates](live-updates.md).

## `CertificatePinner`: trust-on-first-use

[`tls_pinning.dart`](../lib/core/network/tls_pinning.dart) implements the same trust-on-first-use model
the server documents, in the style of SSH host keys:

- The fingerprint is `sha256(cert.der)`, matching the server's own
  `Convert.ToHexString(SHA256.HashData(certificate.RawData))`. It is compared case-insensitively after
  normalization.
- It is wired in as the gRPC channel's `onBadCertificate` handler (`accepts`). That handler **only
  fires when the platform's normal certificate validation fails**, which is exactly the case for the
  self-signed certificate a Raindrop server generates by default. A CA-issued certificate validates
  normally and this handler never runs for it, matching the server's own trust model (see
  [Transport security](../../RaindropServer/docs/transport-security.md)).
  - gRPC's handler is given the host but not the port, so a pinner is built for its channel's own port.
- `pinnedFingerprint == null` means accept and record (a first connection). Otherwise an exact match is
  required. `rejected` remembers whether the last certificate was refused.
- `observedFingerprint` records whatever certificate was actually presented, as a side effect of the
  handshake, so the caller can pin it after a successful first connection. See
  [Connecting to a server](connecting-to-a-server.md).

## `ServerTrust`: following a certificate change

[`server_trust.dart`](../lib/core/network/server_trust.dart) pins the server's long-lived **identity
key** next to the fingerprint. It uses that key to follow a certificate the owner replaced on purpose
(see the server's [Transport security doc](../../RaindropServer/docs/transport-security.md#the-server-identity-key-changing-the-certificate-without-breaking-pins)).

- `verifyTlsBinding` checks the server's ECDSA P-256 signature (`r‖s`) over
  `"raindrop/tls-binding/v1\n" + fingerprint` with pointycastle. Malformed input returns `false`
  instead of throwing.
- `isConsistent(info, presented)` requires two things: the fingerprint `GetServerInfo` advertises is
  the certificate the handshake presented, and the identity key signed it. `ConnectServerFlow.probe`
  runs it on first contact.
- `pinIdentityIfMissing` pins the key over an already-pinned connection.
- `followCertificateChange` runs when a pinned connection fails with `certificate_mismatch`:
  - It makes one unauthenticated `GetServerInfo` call over a probe channel that accepts any
    certificate.
  - It re-pins only if the **pinned** identity key signed the certificate that probe was presented.
  - With no identity key pinned, or with any check failing, the mismatch stands.

  `ServerSessionController` calls it, then retries the restore once.

## The per-domain API wrappers

Each one wraps one `raindrop.v1` service. Their models are plain Dart classes the UI works with, read
from the protobuf messages by `fromProto` factories. The method signatures (token first, then the
request) are what the features call. Each model's class keeps a suffix (`Summary`, `Result`, `Page`)
distinct from the feature-layer UI model built from it (`MemberSummary` → `Member`,
`ChannelSummary` → `Channel`).

| Wrapper | Service (`.proto`) | Doc |
|---|---|---|
| [`UsersApi`](../lib/core/network/users_api.dart) | `ServerService`, `UserService` (`server.proto`, `users.proto`) | [Connecting to a server](connecting-to-a-server.md), [Servers & sessions](servers-and-sessions.md) |
| [`ChannelsApi`](../lib/core/network/channels_api.dart) | `ChannelService` (`channels.proto`) | [Channels](channels.md) |
| [`RolesApi`](../lib/core/network/roles_api.dart) | `RoleService.GetMyRoles` (only) (`roles.proto`) | [Channels](channels.md#creating-renaming-and-deleting) |
| [`MembersApi`](../lib/core/network/members_api.dart) | `MemberService` (`members.proto`) | [Members & presence](members-presence.md) |
| [`TextMessagesApi`](../lib/core/network/text_messages_api.dart) | `TextChannelService` (`text.proto`) | [Messages & chat](messages-chat.md) |
| [`AttachmentsApi`](../lib/core/network/attachments_api.dart) | `AttachmentService` (`attachments.proto`): `upload` is a client stream of frames, `download` a server stream into a file | [Attachments](attachments.md) |
| [`VoiceApi`](../lib/core/network/voice_api.dart) | `VoiceService` (`voice.proto`): call control only | [Voice](voice.md) |
| [`E2eeApi`](../lib/core/network/e2ee_api.dart) | `DeviceService`, `DeliveryService` (`devices.proto`, `delivery.proto`) | [End-to-end encryption](crypto.md) |

`E2eeApi` carries only public keys and opaque blobs, as protobuf `bytes`.

One instance of each wrapper is built per connected server, as `late final` fields on
[`ServerSession`](servers-and-sessions.md#serversession-and-serversessioncontroller--the-live-connection).
They all share that server's one `RaindropChannel`, and so one HTTP/2 connection, with every call and
the event stream multiplexed over it.

The audio of a call does not go through `RaindropChannel` at all. The voice engine (`core/voice/`) opens
its own sockets, which is why [`PinRegistry`](../lib/core/network/pin_registry.dart) and
`PinnedHttpOverrides` exist: a process-wide `HttpOverrides.global` that trusts exactly the fingerprints
this client has pinned. LiveKit's signalling socket to the server's relay therefore gets the same pin
as everything else. See [Voice](voice.md#how-a-call-is-carried).

## Trying it without the app

The network layer depends on `grpc`, `protobuf`, `crypto` and `pointycastle`, plus `SecureStore` for
`ServerTrust`. [`test/integration/transport_test.dart`](../test/integration/transport_test.dart) drives
it against a live server without the Rust core: the handshake and the pin, error codes, and the event
stream. It is the quickest way to check a change here:

```bash
RAINDROP_TEST_SERVER=localhost:5001 flutter test test/integration/transport_test.dart
```

## Related

- [Connecting to a server](connecting-to-a-server.md): where a client's GUID, the fingerprint and the
  session token first come together.
- [Storage](storage.md): where the pinned fingerprint and session token actually live.
- [Wire format](wire-format.md): protobuf, and the encrypted payload inside messages.
