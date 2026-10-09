// Calls the Rust per-frame function the way a capture pipeline does — by
// address, with real planes in native memory — so the one thing no Dart type
// system can check is checked somewhere: that the C signature the platform code
// copies matches the one Rust exports.
//
// Needs the library built first:
//
//   cd ../RaindropCrypto && cargo build -p raindrop_crypto_ffi
//
// and skips itself when it is not there.
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/bridge/api/video.dart';
import 'package:raindrop_client/core/crypto/bridge/frb_generated.dart';

String? _library() {
  const base = '../RaindropCrypto/target/debug/';
  for (final name in [
    'libraindrop_crypto_ffi.dylib',
    'libraindrop_crypto_ffi.so',
    'raindrop_crypto_ffi.dll',
  ]) {
    if (File('$base$name').existsSync()) {
      return File('$base$name').absolute.path;
    }
  }
  return null;
}

/// The signature in `RaindropCrypto/crates/raindrop_crypto_ffi/src/c_api.rs`,
/// and the one `RaindropFrameProcessor.m` and `jni_api.rs` each hand over.
typedef _ProcessNative =
    Int32 Function(
      Int64 context,
      Pointer<Uint8> y,
      Int32 yStride,
      Pointer<Uint8> u,
      Int32 uStride,
      Pointer<Uint8> v,
      Int32 vStride,
      Int32 width,
      Int32 height,
    );

typedef _Process =
    int Function(
      int context,
      Pointer<Uint8> y,
      int yStride,
      Pointer<Uint8> u,
      int uStride,
      Pointer<Uint8> v,
      int vStride,
      int width,
      int height,
    );

void main() {
  final library = _library();

  setUpAll(() async {
    if (library != null) {
      await RustLib.init(externalLibrary: ExternalLibrary.open(library));
    }
  });

  group('camera effects', skip: library == null ? 'Rust library not built' : null, () {
    test('capabilities say whether a model is in this build', () {
      final capabilities = videoEffectsCapabilities();
      expect(capabilities.backend, isNotEmpty);

      // Not asserted either way: a build with the model committed and one
      // without are both valid, and this is exactly the question the UI asks
      // instead of guessing from the platform.
      expect(capabilities.available, isA<bool>());
    });

    test('effects are refused outright when no model is bundled', () async {
      if (videoEffectsCapabilities().available) return;

      await expectLater(
        videoEffectsCreate(
          config: const VideoEffectsConfig(
            kind: 1,
            blurStrength: 0.7,
            maskHz: 15,
          ),
        ),
        throwsA(
          isA<VideoFailure>().having(
            (f) => f.kind,
            'kind',
            VideoFailureKind.unsupported,
          ),
        ),
      );
    });

    test('the per-frame address is callable, and leaves a frame it refuses', () {
      final address = videoEffectsProcessAddress();
      expect(address, isNot(BigInt.zero));

      final process = Pointer<NativeFunction<_ProcessNative>>.fromAddress(
        address.toInt(),
      ).asFunction<_Process>();

      // Deliberately padded strides: that is the case the one `unsafe` in the
      // Rust frame boundary exists for, and the case a cropped camera buffer
      // actually produces.
      const width = 16;
      const height = 8;
      const yStride = 24;
      const chromaStride = 16;
      const chromaRows = height ~/ 2;

      final y = calloc<Uint8>(yStride * height);
      final u = calloc<Uint8>(chromaStride * chromaRows);
      final v = calloc<Uint8>(chromaStride * chromaRows);

      try {
        for (var i = 0; i < yStride * height; i++) {
          y[i] = i % 251;
        }

        // Context 0 is no handle at all, so this is the "effects are gone"
        // path: it must report that it did nothing, and do nothing.
        final outcome = process(
          0,
          y,
          yStride,
          u,
          chromaStride,
          v,
          chromaStride,
          width,
          height,
        );
        expect(outcome, lessThan(0));

        for (var i = 0; i < yStride * height; i++) {
          expect(y[i], i % 251, reason: 'byte $i was written');
        }

        // Nothing checkable is trusted: a frame that cannot be true is
        // reported rather than read.
        expect(
          process(0, y, yStride, u, chromaStride, v, chromaStride, 0, height),
          lessThan(0),
        );
        expect(
          process(0, y, 1, u, chromaStride, v, chromaStride, width, height),
          lessThan(0),
        );
      } finally {
        calloc.free(y);
        calloc.free(u);
        calloc.free(v);
      }
    });
  });
}
