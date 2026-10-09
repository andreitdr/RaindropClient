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

/// The per-frame function, by address, exactly as the platform code gets it.
_Process _processor() => Pointer<NativeFunction<_ProcessNative>>.fromAddress(
  videoEffectsProcessAddress().toInt(),
).asFunction<_Process>();

/// An I420 frame in native memory, with padded strides.
class _Frame {
  _Frame({required this.width, required this.height})
    : yStride = width + 8,
      chromaStride = width ~/ 2 + 4 {
    y = calloc<Uint8>(yStride * height);
    u = calloc<Uint8>(chromaStride * ((height + 1) ~/ 2));
    v = calloc<Uint8>(chromaStride * ((height + 1) ~/ 2));
  }

  final int width;
  final int height;
  final int yStride;
  final int chromaStride;

  late final Pointer<Uint8> y;
  late final Pointer<Uint8> u;
  late final Pointer<Uint8> v;

  /// Stripes rather than flat grey: a blur of a uniform plane is the same
  /// uniform plane, so flat content could not tell blurring from doing nothing.
  void paintStripes() {
    for (var row = 0; row < height; row++) {
      for (var column = 0; column < width; column++) {
        y[row * yStride + column] = _stripe(column);
      }
    }
    for (var row = 0; row < (height + 1) ~/ 2; row++) {
      for (var column = 0; column < width ~/ 2; column++) {
        u[row * chromaStride + column] = 110;
        v[row * chromaStride + column] = 130;
      }
    }
  }

  bool get differsFromStripes {
    for (var row = 0; row < height; row++) {
      for (var column = 0; column < width; column++) {
        if (y[row * yStride + column] != _stripe(column)) return true;
      }
    }
    return false;
  }

  void free() {
    calloc.free(y);
    calloc.free(u);
    calloc.free(v);
  }

  static int _stripe(int column) => (column ~/ 4).isEven ? 30 : 220;
}

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

    test('a build with no model refuses to create effects at all', () async {
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

    test('a real handle really blurs a frame, and a destroyed one does not', () async {
      if (!videoEffectsCapabilities().available) return;

      final handle = await videoEffectsCreate(
        config: const VideoEffectsConfig(
          kind: 1, // blur
          blurStrength: 1,
          maskHz: 15,
        ),
      );

      final process = _processor();
      final frame = _Frame(width: 64, height: 64);

      try {
        // Segmentation runs on its own thread, and frames before the first
        // mask are passed through untouched by design — so this waits for one
        // rather than asserting on the first frame.
        var blurred = false;
        for (var attempt = 0; attempt < 40 && !blurred; attempt++) {
          frame.paintStripes();
          final outcome = process(
            handle.toInt(),
            frame.y,
            frame.yStride,
            frame.u,
            frame.chromaStride,
            frame.v,
            frame.chromaStride,
            frame.width,
            frame.height,
          );
          expect(outcome, 0, reason: 'the effects refused a frame they own');
          blurred = frame.differsFromStripes;
          if (!blurred) await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        expect(
          blurred,
          isTrue,
          reason: 'no mask arrived within two seconds, so nothing was blurred',
        );

        final stats = await videoEffectsStats(handle: handle);
        expect(stats.frames.toInt(), greaterThan(0));
        expect(stats.masks.toInt(), greaterThan(0));
      } finally {
        await videoEffectsDestroy(handle: handle);
      }

      // The handle is gone: a late frame from a pipeline that has not stopped
      // yet must be passed through, not crash and not be written to.
      frame.paintStripes();
      expect(
        process(
          handle.toInt(),
          frame.y,
          frame.yStride,
          frame.u,
          frame.chromaStride,
          frame.v,
          frame.chromaStride,
          frame.width,
          frame.height,
        ),
        lessThan(0),
      );
      expect(frame.differsFromStripes, isFalse);
      frame.free();
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
