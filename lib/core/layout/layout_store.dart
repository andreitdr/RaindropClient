import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'layout_config.dart';

/// The main view's layout on disk: `<app support>/layout.json`, one file for
/// this install, shared by every server. The only code that touches it.
///
/// A file rather than `AppPrefs`, because it is meant to be something the
/// user owns — exported, copied to another machine, imported back.
class LayoutStore {
  LayoutStore(this._directory);

  /// The store in this platform's application-support directory (the same one
  /// `CryptoStores` uses).
  static Future<LayoutStore> open() async =>
      LayoutStore(await getApplicationSupportDirectory());

  final Directory _directory;

  File get file => File('${_directory.path}/layout.json');

  /// The saved layout, or null when there is none — including when the file
  /// cannot be read as a layout. A bad file is moved aside to
  /// `layout.json.bad` rather than left to be overwritten, so a hand edit gone
  /// wrong can still be recovered; the app starts on the default layout.
  Future<LayoutConfig?> load() async {
    final file = this.file;
    if (!await file.exists()) return null;
    try {
      return LayoutConfig.decode(await file.readAsString());
    } on FormatException {
      await file.rename('${file.path}.bad');
      return null;
    }
  }

  /// Writes [config] atomically: to a temporary file first, then renamed over
  /// the old one, so a crash mid-write never leaves half a layout behind.
  Future<void> save(LayoutConfig config) async {
    await _directory.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(config.encode(), flush: true);
    await temp.rename(file.path);
  }

  /// Removes the saved layout; the app goes back to the default one.
  Future<void> delete() async {
    final file = this.file;
    if (await file.exists()) await file.delete();
  }

  /// Reads a layout file the user picked. Throws a [FormatException] when it
  /// is not one.
  static Future<LayoutConfig> readFrom(String path) async =>
      LayoutConfig.decode(await File(path).readAsString());

  /// Writes [config] to a path the user picked. Straight to that file, not
  /// through a temporary one beside it: a sandboxed app (macOS) may write only
  /// the exact file the save dialog handed it.
  static Future<void> writeTo(String path, LayoutConfig config) =>
      File(path).writeAsString(config.encode(), flush: true);
}
