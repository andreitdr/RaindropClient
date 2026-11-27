# raindrop_crypto_ffi (build hook)

A Dart package with no code of its own. Its [build hook](hook/build.dart) compiles the Rust crate
[`RaindropCrypto/crates/raindrop_crypto_ffi`](../../../RaindropCrypto/crates/raindrop_crypto_ffi)
with cargo during every `flutter build`, `flutter run` and `flutter test`, on every platform the
client targets, and Flutter bundles the library it produces. There is no Podfile, Gradle or CMake
glue, which is what lets iOS and macOS build through Swift Package Manager alone.

The hook is [`flutter_rust_bridge_hooks`](https://pub.dev/packages/flutter_rust_bridge_hooks)
(over [`native_toolchain_rust`](https://pub.dev/packages/native_toolchain_rust)), the same 2.13.0 as
the bridge. The Rust toolchain and the targets it can build are pinned in the crate's
`rust-toolchain.toml`.

The Rust code lives in `RaindropCrypto/`, deliberately apart from the Dart and C# trees; the path
into it is `_cratePath` in `hook/build.dart`. See `RaindropClient/docs/crypto.md`.
