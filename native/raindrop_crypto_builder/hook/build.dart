// Builds ../RaindropCrypto/crates/raindrop_crypto_ffi with cargo, for the platform and architecture
// Flutter is building, and hands Flutter the dynamic library to bundle. flutter_rust_bridge's loader
// then opens it by name: raindrop_crypto_ffi.framework/raindrop_crypto_ffi on iOS and macOS,
// libraindrop_crypto_ffi.so on Android and Linux, raindrop_crypto_ffi.dll on Windows.
//
// The Rust toolchain is the one pinned in the crate's rust-toolchain.toml; rustup installs it (and
// its targets) on first use. See RaindropClient/docs/crypto.md.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

/// The crate, from this package's root. The repositories sit side by side.
const _cratePath = '../../../RaindropCrypto/crates/raindrop_crypto_ffi';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final code = input.config.code;

    // The Mac app is Apple silicon only (macos/Runner/Configs/Architectures.xcconfig): an x86_64
    // slice makes ld warn on tract-linalg's x86 kernels. Xcode's ARCHS decides what Flutter asks
    // for, so an x86_64 request means that setting was lost, and building it would hide that.
    if (code.targetOS == OS.macOS &&
        code.targetArchitecture != Architecture.arm64) {
      throw UnsupportedError(
        'The macOS app is built for arm64 only, but this build asked for '
        '${code.targetArchitecture}. Check macos/Runner/Configs/Architectures.xcconfig.',
      );
    }

    await FlutterRustBridgeNativeAssetsBuilder(
      assetName: 'raindrop_crypto_ffi.dart',
      cratePath: _cratePath,
      extraCargoEnvironmentVariables: {
        ..._appleEnvironment(code),
        ..._windowsEnvironment(code),
      },
    ).run(input: input, output: output);
  });
}

/// On iOS and macOS: the app's own minimum version, which cargo is not told otherwise. Rust then
/// links for its default (iOS 10), where the C libraries' stack probe (`___chkstk_darwin`, from
/// SQLCipher) does not exist, and every object built for the SDK's version makes ld warn.
///
/// And line tables: Flutter runs dsymutil over the library before it strips it, and a release
/// build with no debug information makes dsymutil warn ("no debug symbols in executable"). They
/// also give crash reports something to symbolicate; the shipped library is stripped either way.
Map<String, String> _appleEnvironment(CodeConfig code) =>
    switch (code.targetOS) {
      OS.iOS => {
        'IPHONEOS_DEPLOYMENT_TARGET': _version(code.iOS.deploymentVersion),
        'CARGO_PROFILE_RELEASE_DEBUG': 'line-tables-only',
      },
      OS.macOS => {
        'MACOSX_DEPLOYMENT_TARGET': _version(code.macOS.deploymentVersion),
        'CARGO_PROFILE_RELEASE_DEBUG': 'line-tables-only',
      },
      _ => const {},
    };

/// `15.0`, as the deployment-target variables spell it.
String _version(AppleVersion version) => '${version.major}.${version.minor}';

/// What the Windows build needs that it cannot get from the environment: hooks run with only a
/// short list of variables (PATH, LOCALAPPDATA, …), so settings that would otherwise come from the
/// shell are made here.
Map<String, String> _windowsEnvironment(CodeConfig code) {
  if (code.targetOS != OS.windows) return const {};
  final localAppData = Platform.environment['LOCALAPPDATA'];
  return {
    // OpenSSL's build tree (under SQLCipher) is deep enough to pass Windows' 260-character path
    // limit from a hook's own output folder, so cargo builds in a short one instead.
    if (localAppData != null && localAppData.isNotEmpty)
      'CARGO_TARGET_DIR': '$localAppData\\rdcargo',
    // NASM is an x86 assembler: on ARM64 OpenSSL builds without assembly. (tract-linalg's ARM64
    // kernels need clang, which comes from PATH: Visual Studio's LLVM component.)
    if (code.targetArchitecture == Architecture.arm64)
      'OPENSSL_RUST_USE_NASM': '0',
  };
}
