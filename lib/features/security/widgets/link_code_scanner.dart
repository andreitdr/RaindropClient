import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/crypto/crypto_engine.dart';

/// Scans the link code a new device shows, and returns it as text. Only
/// codes that parse as a [DeviceLinkCode] are taken, so a stray QR code in
/// view is ignored rather than tried.
///
/// Scanning is a convenience: the code is exactly what the new device shows
/// as text, and its commitment is what protects the link either way.
Future<String?> scanLinkCode(BuildContext context) => Navigator.of(context)
    .push<String>(MaterialPageRoute(builder: (_) => const _LinkCodeScanner()));

class _LinkCodeScanner extends StatefulWidget {
  const _LinkCodeScanner();

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
      if (text != null && DeviceLinkCode.tryParse(text) != null) {
        _done = true;
        Navigator.of(context).pop(text);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan the link code')),
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
