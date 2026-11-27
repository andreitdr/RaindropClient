# media_kit_video 2.0.1, patched

A copy of [media_kit_video 2.0.1](https://pub.dev/packages/media_kit_video/versions/2.0.1) from
media-kit/media-kit (MIT, see `LICENSE`), used through `dependency_overrides` in the app's
`pubspec.yaml`. Its `example/` folder is left out.

The published release declares `ios` and `macos` plugin platforms that build only through
CocoaPods. Flutter warns about any such plugin ("This will become an error in a future version of
Flutter"), even one the app never calls there, and the app does not: on iOS and macOS, video and
audio play through AVFoundation (`video_player`), see `lib/core/media/`. So this copy removes:

- the `ios:` and `macos:` entries under `flutter: plugin: platforms:` in `pubspec.yaml`;
- the `ios/`, `macos/` and `common/darwin/` folders they used.

Nothing else differs from the release: Android and Linux still play through it, and its `windows:`
entry is unchanged (Windows plays through Media Foundation, so it is registered but unused).

media_kit's `main` has had Swift Package Manager support since PR #1412 (May 2026), unreleased as of
November 2026 (issue #1473). Once a release with it is on pub.dev, delete this folder and the
override; whether iOS and macOS then go back to media_kit is a separate decision.
