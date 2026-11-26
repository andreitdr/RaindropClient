# CI & releases

Two GitHub Actions workflows live in [`.github/workflows/`](../.github/workflows), plus the packaging
scripts in [`packaging/`](../packaging) that the release workflow calls.

## The side-by-side checkout CI has to reproduce

The app compiles the Rust crypto core from the **sibling** repository through
[`native/raindrop_crypto_builder`](crypto.md#building), whose paths point at `../RaindropCrypto`. Both
workflows therefore check out two repositories into one workspace — `RaindropClient/` next to
`RaindropCrypto/` — and run every step with `working-directory: RaindropClient`, mirroring a local
clone of all three projects in one folder.

RaindropCrypto is checked out at its **current `main`**, not at a matching tag, even in a release. If
that repository is private, a repository secret `CRYPTO_REPO_TOKEN` (a fine-grained token with
read-only Contents access to it) is required, since the default `GITHUB_TOKEN` cannot read another
repository; `release.yml` passes it on with `secrets: inherit`.

## `ci.yml` — build and test

Runs on every push to `main`, and as the first stage of `release.yml`. A newer push cancels a run
still in progress.

| Job | Runners | Does |
|---|---|---|
| `build` | `linux` (`ubuntu-latest`), `macos` (`macos-latest`), `windows` (`windows-latest`), `android` (`ubuntu-latest`), `ios` (`macos-latest`); `fail-fast: false` | `flutter pub get`, `flutter analyze` (on Linux only — it is platform-independent), then `flutter build <platform> --release` (`apk` for Android, `ios --no-codesign` for iOS) |
| `test` | `ubuntu-latest`, after `build` | `flutter test` — the unit tests. The integration tests skip themselves because `RAINDROP_TEST_SERVER` is unset |

**Warnings are errors, on every platform.** A release cannot be published while any platform has a
compilation error or a warning: `release.yml` runs this workflow first and packages nothing unless every
`build` job succeeds, and each of them fails on a warning in this repository's own code:

| Code | Where the rule is set |
|---|---|
| Dart | `flutter analyze --fatal-infos --fatal-warnings` in the Linux job (infos — lints, deprecations — fail too) |
| Rust (the crypto core and camera effects) | `RaindropCrypto`'s `[workspace.lints.rust] warnings = "deny"`, which holds inside cargokit's build for all five targets |
| Swift, iOS (Runner, RaindropBroadcast) | `SWIFT_TREAT_WARNINGS_AS_ERRORS` in [`ios/Flutter/Warnings.xcconfig`](../ios/Flutter/Warnings.xcconfig), included by `Debug`/`Release.xcconfig` and `Broadcast.xcconfig` |
| Swift, macOS (Runner) | the same in [`macos/Runner/Configs/Warnings.xcconfig`](../macos/Runner/Configs/Warnings.xcconfig) |
| Objective-C, camera-effects plugin | `.treatAllWarnings(as: .error)` in both `Package.swift` files (tools 6.2, hence the newest stable Xcode on the Apple runners) |
| Kotlin / Java, Android app | `allWarningsAsErrors` and `-Xlint:all -Werror` in `android/app/build.gradle.kts` |
| Java, the two local plugins | `-Xlint:all -Werror` in their `android/build.gradle` |
| C++, Windows and Linux runners | `/W4 /WX` and `-Wall -Werror` in `apply_standard_settings` (Flutter's template) |

Third-party plugins and pods build under their own settings and still print warnings (OpenGL ES
deprecations in `media_kit_video`, Java 8 targets, the Kotlin Gradle plugin deprecation); those are
theirs to fix and do not fail the build. That is also why Runner does not set
`GCC_TREAT_WARNINGS_AS_ERRORS`: clang would apply it while precompiling plugins' generated Swift
headers for Runner to import, and `media_kit_video`'s and `mobile_scanner`'s warn. So does the Gradle script deprecation on `android {}` in
`app/build.gradle.kts`, which goes away only with `android.newDsl=true` — and that waits on the
plugins that still apply the Kotlin Gradle plugin themselves (`desktop_drop`, `flutter_webrtc`,
`livekit_client`). Everything that is ours is fixed when it warns, never suppressed.

**Flutter is pinned** (`FLUTTER_VERSION` at the top of both workflows) to the release the app is
developed with, rather than following the latest stable. A new Flutter can deprecate things, and
`flutter analyze` treats its deprecation notices as failures. Flutter 3.50 deprecated importing
`package:flutter/material.dart` and `cupertino.dart`, which failed the Linux job on 45 notices while
nothing in the repository had changed. To move CI forward, upgrade Flutter locally first, fix what
`flutter analyze` reports, and then change the pin.

**Android's licences** are accepted with `(yes || true) | sdkmanager --licenses`. The steps run with
`pipefail`, and `yes` fails with "Broken pipe" once `sdkmanager` stops reading, which on its own failed
the job before anything was built.

**Android needs room.** It builds the Rust core three times (one per ABI), each in release with fat
LTO and one codegen unit, with OpenSSL and SQLCipher from source, next to the NDK and Gradle. On a
stock runner the runner was shut down partway through the first ABI. So the job first deletes large
toolchains it never uses (.NET, GHC, Boost, CodeQL, Swift, PowerShell, cached Docker images) and adds
8 GB of swap on `/mnt`. While it builds, it logs disk and memory use once a minute (`[resources]`
lines), so if it is shut down again, the log shows which one ran out.

Three workarounds in the build. The first two are runner-only and undone with the checkout:

- **macOS signing.** The project signs with the developer's own Apple Development certificate, which
  CI does not have, so `project.pbxproj` is rewritten to ad-hoc signing (and the step fails if any
  `Apple Development` identity survives).
- **Windows OpenSSL.** `rusqlite`'s bundled SQLCipher builds OpenSSL from source, which needs
  Strawberry Perl and NASM; Git Bash otherwise puts Git's cut-down Perl first on `PATH`, and
  OpenSSL's `Configure` fails on it.
- **Windows path length.** OpenSSL's build tree under cargokit's default folder exceeds the
  260-character limit. `cargokit.cmake` moves the Rust build to `%LOCALAPPDATA%\rdcargo` on every
  Windows machine; CI sets `RAINDROP_CARGO_BUILD_DIR=C:/ck` to make it shorter still. See
  [Building on Windows](building-on-windows.md#path-length).

Integration tests are **not** run in CI: they need a live server with a fresh database. Run them
locally — see [Crypto](crypto.md#tests) for the full set and the `RAINDROP_TEST_SERVER` form.

Two more gaps worth naming, both local-only on purpose:

- The two tests that load the Rust library directly (`test/core/crypto/mls_crypto_engine_test.dart`
  and `test/core/video/camera_effects_test.dart`) look for it under
  `../RaindropCrypto/target/debug/`, which a `flutter build` does not produce — cargokit builds into
  its own tree. They skip themselves in CI and run after a `cargo build -p raindrop_crypto_ffi`.
- **Android and iOS are compiled in CI but never run**, so the Android half of
  [`native/raindrop_camera_effects`](voice.md#camera-effects) — the JNI binding in particular, which
  resolves by name at the first frame rather than at compile time — is only verified by running the
  app on a device.

## `release.yml` — package and publish

Triggered by a pushed version tag matching `v[0-9]+.[0-9]+.[0-9]+`.

1. **`ci`** — reruns `ci.yml` against the tagged commit, so nothing is published that did not build
   on every platform without an error or a warning, analyse clean and pass its tests.
2. **`package`** — builds `flutter build <platform> --release --build-name <tag without v>` and wraps
   the bundle:

   | Platform | Runner | Artefact |
   |---|---|---|
   | Linux | `ubuntu-22.04` (deliberately the oldest supported: a bundle runs on the glibc it was built with or newer) | AppImage, `.deb` and `.rpm`, via [`packaging/linux/bundle-libs.sh`](../packaging/linux/bundle-libs.sh) (which copies in libmpv) and [`build-packages.sh`](../packaging/linux/build-packages.sh) |
   | macOS | `macos-latest` | `.dmg` with the app and an Applications shortcut (`ditto` keeps symlinks and signatures). Apple silicon only — see below |
   | Windows | `windows-latest` | `.zip` with the Visual C++ runtime DLLs copied in beside the exe, so a clean PC can run it |

3. **`release`** — reads the changelog from the annotated tag (its message minus the subject line,
   written there by `release.sh`) and runs `gh release create <tag> dist/* --verify-tag
   --notes-file notes.md`, so the changelog becomes the release notes. A lightweight tag pushed by
   hand carries none, and the release falls back to `--generate-notes`.

Each project is tagged in its own repository, and the workflow comments point at a `release.sh` in
the folder that holds all three checkouts. That script is not part of this repository. Every release
it makes carries a changelog: drafted from the commit subjects since the previous tag (editable before
tagging) or taken from `--notes-dir DIR/<Repo>.md`. Tagging by hand
(`git tag vX.Y.Z && git push origin vX.Y.Z`) triggers the same workflow; use an annotated tag
(`git tag -a vX.Y.Z --cleanup=verbatim -F notes`) to keep the changelog.

## What CI does not do

- **No mobile artefacts.** Desktop only; no `.apk`, `.aab` or TestFlight build. See
  [Roadmap](roadmap.md).
- **No real code signing or notarisation.** macOS builds are ad-hoc signed, Windows unsigned.
- **No Intel Mac build.** The macOS app is arm64 only: `ARCHS = arm64` in
  [`macos/Runner/Configs/Architectures.xcconfig`](../macos/Runner/Configs/Architectures.xcconfig), and
  the Podfile's `post_install` sets the same on every pod, which is also what tells cargokit to build
  the Rust core for arm64 alone. An x86_64 slice would link tract-linalg's x86 kernels (the camera
  effects' inference), whose `.align 16` is 64 KiB on Mach-O, so `ld` warns while linking
  `raindrop_crypto_ffi` — and a warning fails the release.
- **No integration tests**, for want of a server.
- No PR trigger: `push` to `main` only.

## Related

- [Crypto](crypto.md#building) — what the Rust build needs locally, and the `flutter_rust_bridge`
  version pin that must match in three places.
- The other projects' pipelines: [RaindropServer](../../RaindropServer/docs/ci-and-releases.md),
  [RaindropCrypto](../../RaindropCrypto/docs/ci-and-releases.md).
