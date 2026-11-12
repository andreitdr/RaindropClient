# RaindropClient

The cross-platform client for **Raindrop**, a decentralised, self-hosted chat platform. Flutter,
targeting **macOS, Windows, Linux, iOS and Android** (web is not a target). It connects to any number
of independent Raindrop servers, each with its own pinned certificate, its own identity for this
install, and its own encrypted local store.

Messages, files and call media are **end-to-end encrypted** with MLS (RFC 9420): the app drives each
channel's MLS group itself, through a Rust core it compiles into the binary.

## The three Raindrop projects

Checked out side by side in one folder — **this is not optional**, since the app builds the crypto
core from its sibling:

| Project | What it is |
|---|---|
| **RaindropClient** (this repo) | The app: servers, channels, chat, attachments, voice, layout and theming |
| [`../RaindropCrypto`](../RaindropCrypto) | The Rust end-to-end encryption core, compiled in by `native/raindrop_crypto_builder` |
| [`../RaindropServer`](../RaindropServer) | The self-hosted .NET backend. This app is its only client, so `lib/core/network/` must track its API exactly |

## Documentation

**[`docs/`](docs/README.md) is the reference wiki** — one file per area, kept current with the code.
Start with:

- [Architecture overview](docs/architecture-overview.md) — the `core/` vs. `features/` split
- [Roadmap](docs/roadmap.md) — what is implemented, what is not, what is not planned
- [Connecting to a server](docs/connecting-to-a-server.md) and [Servers & sessions](docs/servers-and-sessions.md)
- [Crypto](docs/crypto.md) — the Rust core, the bridge, and what building it needs
- [CI & releases](docs/ci-and-releases.md) — the workflows and the desktop packaging

[`CLAUDE.md`](CLAUDE.md) is the condensed guide for coding agents working in this repository.

## Running it

Needs the Flutter SDK, a Rust toolchain on `PATH` (for the crypto core) and, on macOS/iOS,
CocoaPods — see [Crypto → Building](docs/crypto.md#building). **On Windows** the crypto core's
OpenSSL also needs Visual Studio's C++ workload, Strawberry Perl, NASM and Developer Mode: see
[Building on Windows](docs/building-on-windows.md) for the full list with download links.

```bash
flutter pub get
```

```bash
flutter run -d macos
```

The first build takes a few minutes while SQLCipher and OpenMLS compile. Point the app at a server
you run yourself (`dotnet run --project ServerCli` in `../RaindropServer` listens on
`https://localhost:5001`) — the first connection pins its self-signed certificate.

```bash
flutter analyze && flutter test
```

Integration tests need a live server with a fresh database and skip themselves otherwise:

```bash
RAINDROP_TEST_SERVER=localhost:5097 flutter test test/integration
```

## Keeping the docs current

Changing a feature means changing its doc in the same commit: a new screen, a changed controller, a
new provider, a new dependency, a change to how the client talks to the server. If the change touches
the server's API contract or a crypto byte format, update that project's docs too.
