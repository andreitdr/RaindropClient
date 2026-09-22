# raindrop_crypto_ffi (build glue)

A Flutter FFI plugin with no code of its own. At build time it compiles the Rust crate
[`RaindropCrypto/crates/raindrop_crypto_ffi`](../../../RaindropCrypto/crates/raindrop_crypto_ffi)
through [cargokit](cargokit/README) and links the result into the app, on every platform the client
targets (CocoaPods script phase on iOS/macOS, CMake on Linux/Windows, Gradle on Android).

The Rust code lives in `RaindropCrypto/`, deliberately apart from the Dart and C# trees. The paths
into it are in `ios/` and `macos/*.podspec`, `linux/` and `windows/CMakeLists.txt`, and
`android/build.gradle`. Update them together if either folder moves.

Generated from the flutter_rust_bridge 2.13.0 template; see `RaindropClient/docs/crypto.md`.
