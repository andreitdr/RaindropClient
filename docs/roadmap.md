# Roadmap / what's missing

Known gaps between what [RaindropServer](../../RaindropServer/docs/README.md) already supports and
what this client currently exposes. Keep this file honest — when one of these ships, move it out
rather than leaving it here stale.

## Voice: what the first version leaves out

Voice channels work (see [Voice](voice.md)). Not yet:

- **Background audio on phones** — iOS has no background audio mode set and Android has no microphone
  foreground service, so a call stops being heard when the app is backgrounded.
- **Rejoining after a dropped connection** — the call ends with a notice; you join again.
- **Push-to-talk**, **camera and screen sharing**, and a **microphone volume** (the voice library has no
  input gain on desktop; automatic gain control stands in for it).

## MessagePack wire format

Server-side fully implemented and negotiable; client sends JSON unconditionally. See
[Wire format](wire-format.md) for what adopting it would involve.

## Related

- [Voice](voice.md), [Wire format](wire-format.md) — the fuller context for each gap above.
