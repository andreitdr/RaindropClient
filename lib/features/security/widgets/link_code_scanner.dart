import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans the code a new device shows, and returns it as text. Only codes
/// [accepts] recognises are taken, so a stray QR code in view is ignored
/// rather than tried.
///
/// Scanning is a convenience: the code is exactly what the new device shows
/// as text, and its commitment is what protects the pairing either way.
Future<String?> scanCode(
  BuildContext context, {
  required bool Function(String text) accepts,
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(builder: (_) => _LinkCodeScanner(accepts: accepts)),
);

class _LinkCodeScanner extends StatefulWidget {
  const _LinkCodeScanner({required this.accepts});

  final bool Function(String text) accepts;

  @override
  State<_LinkCodeScanner> createState() => _LinkCodeScannerState();
}

class _LinkCodeScannerState extends State<_LinkCodeScanner> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final text = barcode.rawValue;
      if (text != null && widget.accepts(text)) {
        _done = true;
        Navigator.of(context).pop(text);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan the code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'The camera is not available (${error.errorCode.name}). '
                  'Type the code instead.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Point the camera at the code on the new device.',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
