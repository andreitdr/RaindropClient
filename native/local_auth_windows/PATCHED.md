# local_auth_windows 2.0.2, patched

A copy of [local_auth_windows 2.0.2](https://pub.dev/packages/local_auth_windows/versions/2.0.2) from
flutter/packages (BSD-3-Clause, see `LICENSE`), used through `dependency_overrides` in the app's
`pubspec.yaml`. Its `example/` and Dart `test/` folders are left out.

Visual Studio 18 (MSVC 14.51) no longer compiles the published release:

- `windows/CMakeLists.txt` builds with `/await`, MSVC's pre-standard coroutines, which the STL now
  refuses (`error STL1011`). The plugin already builds as C++20, where C++/WinRT uses standard
  coroutines, so `/await` is removed for the plugin and its test runner.
- `windows/local_auth_plugin.cpp` ends `RequestVerificationForWindowAsync` with `return` instead of
  `co_return`, which is an error (C3773) in standard C++20. It now says `co_return`.

Nothing else differs from the release. Once flutter/packages publishes a version with both fixed,
delete this folder and the override.
