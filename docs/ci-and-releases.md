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
| `build` | `ubuntu-latest`, `macos-latest`, `windows-latest` (`fail-fast: false`) | `flutter pub get`, `flutter analyze` (on Linux only — it is platform-independent), `flutter build <platform> --release` |
| `test` | `ubuntu-latest`, after `build` | `flutter test` — the unit tests. The integration tests skip themselves because `RAINDROP_TEST_SERVER` is unset |

Three runner-only workarounds in the build, each undone with the checkout:

- **macOS signing.** The project signs with the developer's own Apple Development certificate, which
  CI does not have, so `project.pbxproj` is rewritten to ad-hoc signing (and the step fails if any
  `Apple Development` identity survives).
- **Windows OpenSSL.** `rusqlite`'s bundled SQLCipher builds OpenSSL from source, which needs
  Strawberry Perl and NASM; Git Bash otherwise puts Git's cut-down Perl first on `PATH`, and
  OpenSSL's `Configure` fails on it.
- **Windows path length.** OpenSSL's build tree under cargokit's default folder exceeds the
  260-character limit inside the doubled workspace path, so the build is redirected to `C:/ck`.

Integration tests are **not** run in CI: they need a live server with a fresh database. Run them
locally — see [Crypto](crypto.md#tests) for the full set and the `RAINDROP_TEST_SERVER` form.

Two more gaps worth naming, both local-only on purpose:

- The two tests that load the Rust library directly (`test/core/crypto/mls_crypto_engine_test.dart`
  and `test/core/video/camera_effects_test.dart`) look for it under
  `../RaindropCrypto/target/debug/`, which a `flutter build` does not produce — cargokit builds into
  its own tree. They skip themselves in CI and run after a `cargo build -p raindrop_crypto_ffi`.
- **Android is not built in CI**, so the Android half of
  [`native/raindrop_camera_effects`](voice.md#camera-effects) — the JNI binding in particular, which
  resolves by name at the first frame rather than at compile time — is only verified by a local
  `flutter build apk`. Adding an Android job means an SDK, an NDK and a third Rust target matrix.

## `release.yml` — package and publish

Triggered by a pushed version tag matching `v[0-9]+.[0-9]+.[0-9]+`.

1. **`ci`** — reruns `ci.yml` against the tagged commit, so nothing is published that did not build,
   analyse and pass its tests.
2. **`package`** — builds `flutter build <platform> --release --build-name <tag without v>` and wraps
   the bundle:

   | Platform | Runner | Artefact |
   |---|---|---|
   | Linux | `ubuntu-22.04` (deliberately the oldest supported: a bundle runs on the glibc it was built with or newer) | AppImage, `.deb` and `.rpm`, via [`packaging/linux/bundle-libs.sh`](../packaging/linux/bundle-libs.sh) (which copies in libmpv) and [`build-packages.sh`](../packaging/linux/build-packages.sh) |
   | macOS | `macos-latest` | `.dmg` with the app and an Applications shortcut (`ditto` keeps symlinks and signatures) |
   | Windows | `windows-latest` | `.zip` with the Visual C++ runtime DLLs copied in beside the exe, so a clean PC can run it |

3. **`release`** — `gh release create <tag> dist/* --verify-tag --generate-notes`.

Each project is tagged in its own repository, and the workflow comments point at a `release.sh` in
the folder that holds all three checkouts. That script is not part of this repository — tagging by
hand (`git tag vX.Y.Z && git push origin vX.Y.Z`) triggers the same workflow.

## What CI does not do

- **No mobile artefacts.** Desktop only; no `.apk`, `.aab` or TestFlight build. See
  [Roadmap](roadmap.md).
- **No real code signing or notarisation.** macOS builds are ad-hoc signed, Windows unsigned.
- **No integration tests**, for want of a server.
- No PR trigger: `push` to `main` only.

## Related

- [Crypto](crypto.md#building) — what the Rust build needs locally, and the `flutter_rust_bridge`
  version pin that must match in three places.
- The other projects' pipelines: [RaindropServer](../../RaindropServer/docs/ci-and-releases.md),
  [RaindropCrypto](../../RaindropCrypto/docs/ci-and-releases.md).
