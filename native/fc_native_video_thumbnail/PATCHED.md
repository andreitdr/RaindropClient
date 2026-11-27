# fc_native_video_thumbnail 4.0.0, patched

A copy of [fc_native_video_thumbnail 4.0.0](https://pub.dev/packages/fc_native_video_thumbnail/versions/4.0.0)
(MIT, see `LICENSE`), used through `dependency_overrides` in the app's `pubspec.yaml`. Its
`example/` folder is left out.

The app uses it only where media_kit cannot grab a still from a video, which is wherever video plays
through the system's own player: iOS and macOS (AVFoundation, Swift Package Manager) and Windows
(the shell's thumbnail cache). Android and Linux keep grabbing stills through media_kit. The
release's Linux implementation, though, needs FFmpeg's development libraries at build time
(`pkg_check_modules(FFMPEG REQUIRED …)`), and every build would carry an Android implementation
nobody calls. So this copy removes:

- the `android:` and `linux:` entries under `flutter: plugin: platforms:` in `pubspec.yaml`;
- the `android/` and `linux/` folders they used.

It also runs on the app's minimum versions, iOS 15 and macOS 12, where the release needs iOS 16 and
macOS 13 for one call:

- `darwin/.../Impl.swift` grabs the frame with `AVAssetImageGenerator.image(at:)` where it exists
  (iOS 16, macOS 13) and with `copyCGImage(at:actualTime:)`, on a detached task, before that;
- `darwin/.../Package.swift` and the podspec declare iOS 15.0 and macOS 12.0.

Nothing else differs from the release. If the app ever calls it on Android or Linux, drop the first
change rather than patching further; once the app's minimums reach iOS 16 and macOS 13, drop the
second.
