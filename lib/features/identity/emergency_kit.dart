import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as picker;
import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/platform/platform_info.dart';

/// The emergency kit: one printable page holding what it takes to get back
/// in with every device gone — the recovery words, or the authenticator's
/// backup codes, or both — and the servers to recover from.
///
/// It can only be made at the moment those are on screen: the words exist
/// nowhere once their dialog closes (a device keeps only the seed made from
/// them), and the server keeps only hashes of the backup codes.
///
/// The PDF uses the built-in Helvetica, which has no Unicode, so nothing but
/// the words (BIP-39 English), the codes and server addresses goes in it.
Future<Uint8List> buildEmergencyKit({
  List<String> words = const [],
  List<String> backupCodes = const [],
  List<String> servers = const [],
  DateTime? madeAt,
}) {
  final date = DateFormat('d MMMM y').format(madeAt ?? DateTime.now());
  final doc = pw.Document(title: 'Raindrop emergency kit', creator: 'Raindrop');
  const mono = pw.TextStyle(fontSize: 12);
  final heading = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  final small = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);

  pw.Widget box(List<pw.Widget> children) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    ),
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Raindrop emergency kit',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Made $date', style: small),
          pw.SizedBox(height: 12),
          pw.Text(
            'Keep this page somewhere safe and private, like a drawer at home '
            'or a safe. Anyone who has it can get into your Raindrop '
            'accounts. Nobody can recover any of this for you, including the '
            'owners of your servers.',
          ),
          pw.SizedBox(height: 16),
          if (words.isNotEmpty) ...[
            pw.Text('Recovery words', style: heading),
            pw.SizedBox(height: 6),
            box([
              pw.Wrap(
                runSpacing: 6,
                children: [
                  for (var i = 0; i < words.length; i++)
                    pw.SizedBox(
                      width: 120,
                      child: pw.Text('${i + 1}. ${words[i]}', style: mono),
                    ),
                ],
              ),
            ]),
            pw.SizedBox(height: 16),
          ],
          if (backupCodes.isNotEmpty) ...[
            pw.Text('Authenticator backup codes', style: heading),
            pw.SizedBox(height: 6),
            box([
              pw.Text(
                'Each works once in place of an authenticator code.',
                style: small,
              ),
              pw.SizedBox(height: 6),
              pw.Wrap(
                runSpacing: 6,
                children: [
                  for (final code in backupCodes)
                    pw.SizedBox(width: 240, child: pw.Text(code, style: mono)),
                ],
              ),
            ]),
            pw.SizedBox(height: 16),
          ],
          pw.Text('Your servers', style: heading),
          pw.SizedBox(height: 6),
          box([
            pw.Text(
              'Recovering needs the address of one server you are on. Add '
              'any you join later.',
              style: small,
            ),
            pw.SizedBox(height: 6),
            for (final server in servers) pw.Text(server, style: mono),
            for (var i = servers.length; i < 4; i++) ...[
              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            ],
          ]),
          pw.SizedBox(height: 16),
          pw.Text('If you lose every device', style: heading),
          pw.SizedBox(height: 6),
          pw.Bullet(
            text: 'Install Raindrop and choose "Use my recovery words".',
          ),
          pw.Bullet(text: 'Enter one server address above and the 24 words.'),
          pw.Bullet(
            text:
                'If you set up an authenticator, give a code from it, or one '
                'of the backup codes if it went with your devices.',
          ),
          pw.Bullet(
            text:
                'Your other servers come back on their own. Then make new '
                'recovery words and a new emergency kit.',
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

/// The file name a kit is offered under.
String emergencyKitFileName(DateTime at) =>
    'raindrop-emergency-kit-${DateFormat('yyyy-MM-dd').format(at)}.pdf';

/// Asks where to save [bytes] and writes them there. Returns whether a file
/// was written; false when the person cancelled.
Future<bool> saveEmergencyKit(Uint8List bytes, {DateTime? madeAt}) async {
  final name = emergencyKitFileName(madeAt ?? DateTime.now());
  if (isDesktopPlatform) {
    final location = await selector.getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [
        selector.XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
    );
    if (location == null) return false;
    await File(location.path).writeAsBytes(bytes, flush: true);
    return true;
  }
  // Phones save through the system's own dialog, which takes the bytes.
  final saved = await picker.FilePicker.saveFile(
    fileName: name,
    bytes: bytes,
    type: picker.FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  return saved != null;
}

/// A button that builds a kit from [build] and saves it, saying how that
/// went. Shared by the recovery words and the backup codes dialogs.
class EmergencyKitButton extends StatefulWidget {
  const EmergencyKitButton({super.key, required this.build});

  final Future<Uint8List> Function() build;

  @override
  State<EmergencyKitButton> createState() => _EmergencyKitButtonState();
}

class _EmergencyKitButtonState extends State<EmergencyKitButton> {
  bool _busy = false;

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      if (await saveEmergencyKit(await widget.build())) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text(
              'Emergency kit saved. Print it, then delete the file.',
            ),
          ),
        );
      }
    } on Object catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not save the emergency kit: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: _busy ? null : _save,
    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
    label: const Text('Save emergency kit'),
  );
}
