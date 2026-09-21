# Wire format

The server negotiates JSON or MessagePack per request via `Content-Type`/`Accept` (see the server's
[Wire formats doc](../../RaindropServer/docs/wire-formats.md)), and documents that MessagePack's win
only really shows up on larger, more numeric payloads than user-management traffic — GUIDs and
PascalCase keys eat most of the savings on small objects.

**This client only speaks JSON today.** [`ApiClient`](network-layer.md#apiclient--the-transport) sends
`Content-Type`/`Accept: application/json` unconditionally — there's no negotiation logic on the client
side at all yet. The [event stream](live-updates.md) asks for JSON the same way, so the server sends it
text frames; `EventStream` ignores binary frames, which would be MessagePack.

## MessagePack readiness

The `msgpack_dart` package is already listed in [`pubspec.yaml`](../pubspec.yaml) as a dependency, but
**unused** — nothing currently encodes or decodes with it. The natural point to add it is once chat
history or voice metadata (numeric, repetitive payloads — exactly what the server's own notes say
MessagePack actually pays off on) is the thing being fetched at volume; see the server's reasoning in
[Wire formats](../../RaindropServer/docs/wire-formats.md#is-the-binary-format-actually-worth-it).

Adding it would mean:

1. Encoding request bodies with `msgpack_dart` and setting `Content-Type: application/x-msgpack` in
   `ApiClient`.
2. Setting `Accept: application/x-msgpack` and decoding responses accordingly.
3. Keeping the two wire formats interchangeable per the server's negotiation model — nothing about the
   server requires an all-or-nothing switch, so this could be introduced per-domain (e.g. message
   history first) rather than everywhere at once.

## Related

- [Network layer](network-layer.md) — `ApiClient`, where this would change.
- [Roadmap](roadmap.md) — tracked as a known gap.
