import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stands for [ThemeCatalogController]'s "match system" pseudo-theme —
/// resolved at render time to the built-in `light` or `dark` theme based on
/// the OS's current brightness. Lives here (rather than `theme_controller`)
/// so `AppPrefs`'s default doesn't need a Flutter UI import.
const kSystemThemeId = 'system';

/// Thin wrapper around [SharedPreferences] for small, non-sensitive UI
/// settings (the active theme, custom themes, which server was open last).
/// Anything sensitive — GUIDs, pinned fingerprints, session tokens — lives
/// in `SecureStore` instead, never here.
class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const _kActiveThemeId = 'settings.active_theme_id';
  static const _kCustomThemes = 'themes.custom';
  static const _kLastServerId = 'settings.last_server_id';
  static const _kServers = 'servers.list';
  static const _kVoiceSettings = 'voice.settings';
  // The name stayed when per-member *audio* became per-member *media* (a
  // hidden camera lives here too now): renaming the key would silently throw
  // away every volume anybody has ever set.
  static const _kMemberAudio = 'voice.member_audio';

  /// The id of the currently selected theme: `"system"`, one of the two
  /// built-in ids (`"light"`/`"dark"`), or a custom theme's generated id.
  String get activeThemeId =>
      _prefs.getString(_kActiveThemeId) ?? kSystemThemeId;

  Future<void> setActiveThemeId(String id) =>
      _prefs.setString(_kActiveThemeId, id);

  /// User-created themes, as raw JSON maps (see `AppThemeDefinition.toJson`).
  /// Kept format-agnostic here, same as [serverProfilesJson] below, so this
  /// storage layer never has to import a theme model.
  List<Map<String, dynamic>> get customThemesJson {
    final raw = _prefs.getString(_kCustomThemes);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setCustomThemesJson(List<Map<String, dynamic>> themes) =>
      _prefs.setString(_kCustomThemes, jsonEncode(themes));

  String? get lastServerId => _prefs.getString(_kLastServerId);

  Future<void> setLastServerId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kLastServerId);
    } else {
      await _prefs.setString(_kLastServerId, id);
    }
  }

  /// The connected-servers list, as raw JSON maps. Kept format-agnostic here
  /// (rather than returning `ServerProfile`) so this storage layer never has
  /// to import a domain model.
  List<Map<String, dynamic>> get serverProfilesJson {
    final raw = _prefs.getString(_kServers);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setServerProfilesJson(List<Map<String, dynamic>> profiles) =>
      _prefs.setString(_kServers, jsonEncode(profiles));

  /// Voice and audio settings (devices, output volume, processing, and
  /// whether this client is muted or deafened), as a raw JSON map — see
  /// `VoiceSettings.toJson`.
  Map<String, dynamic> get voiceSettingsJson {
    final raw = _prefs.getString(_kVoiceSettings);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> setVoiceSettingsJson(Map<String, dynamic> settings) =>
      _prefs.setString(_kVoiceSettings, jsonEncode(settings));

  /// Per-member volume, local mute and hidden camera, keyed `serverId/userId`
  /// — a member's UUID only means something on one server.
  Map<String, dynamic> get memberAudioJson {
    final raw = _prefs.getString(_kMemberAudio);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> setMemberAudioJson(Map<String, dynamic> audio) =>
      _prefs.setString(_kMemberAudio, jsonEncode(audio));
}
