# Wire format

There is one, **protobuf over gRPC**, defined in RaindropProto (`raindrop/v1/*.proto`; see its
[conventions](../../RaindropProto/docs/conventions.md)). Every call, response, event and error this
client exchanges with a server is a protobuf message on an HTTP/2 connection inside TLS. The client
once spoke JSON over REST and a JSON WebSocket; both are gone, together with `dio`.

What this client relies on from the conventions:

- **UUIDs are lower-case strings.** Device certificates and attestations sign them as text.
- **Times are `Timestamp`s.** [`Wire.time`](../lib/core/network/grpc/wire.dart) reads them as UTC.
- **Crypto blobs are `bytes`.** No base64 anywhere on the wire.
- **Open sets stay strings.** Permissions, channel types, voice leave reasons, capabilities and payload
  types: a name this build does not know is ignored.
- **Closed sets are enums.** Presence, user state, role kind, attachment kind and upload state; `Wire`
  turns each one back into the name the app works with.
- **Absent versus empty** is carried by `optional` fields and wrapper messages. For example, a report's
  `attested_files` is present only for a message with files, which is what makes its attestation v2.
- **Errors are statuses** with an `ErrorInfo.reason`; see [Network layer](network-layer.md#apiexception).

The one connection that is not gRPC is a call's signalling: LiveKit's own WebSocket, relayed by the
server, with LiveKit's protobuf inside. See [Voice](voice.md).

## Inside an end-to-end encrypted message

The plaintext the MLS layer encrypts, `MessagePayload`
([`message_payload.dart`](../lib/core/crypto/message_payload.dart)), is protobuf too: RaindropProto's
`payload.proto`. Only clients ever see it.

- **Version 2**, which this build writes, is the byte `0x02` followed by a `raindrop.v1.MessagePayload`:
  type, body, client message id, send time, attestation, and the files of a `files` message.
- **Version 1** was MessagePack (`{v: 1, t, b, c, s, x: {f}, a}`). Its first byte is always a map
  marker, never `0x02`, so `tryDecode` tells the two apart from that one byte. It still reads v1, which
  means history and cached messages from before the switch decrypt as they did. `msgpack_dart` stays a
  dependency for that alone.
- **The attestation bytes are built from fields, not from either encoding** (`attestationBytes`), so
  a report's proof is the same in both versions and the server checks it unchanged.
- **A newer version is not guessed at.** A first byte above `0x02` decodes to null and is shown as a
  placeholder, the same as garbage.

## Related

- [Network layer](network-layer.md): the transport and the generated code.
- [End-to-end encryption](crypto.md): what encrypts the payload.
