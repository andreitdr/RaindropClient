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
  static const _kIdentityVault = 'identity.vault';
  static const _kHiddenServers = 'identity.hidden_servers';
  static const _kDeviceName = 'identity.device_name';
  static const _kBackgroundSettings = 'settings.background';

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

  /// Whether closing the window keeps the app running, and whether a call is
  /// shown outside the app, as a raw JSON map — see `BackgroundSettings.toJson`.
  Map<String, dynamic> get backgroundSettingsJson {
    final raw = _prefs.getString(_kBackgroundSettings);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> setBackgroundSettingsJson(Map<String, dynamic> settings) =>
      _prefs.setString(_kBackgroundSettings, jsonEncode(settings));

  /// Per-member volume, local mute and hidden camera, keyed `serverId/userId`
  /// — a member's UUID only means something on one server.
  Map<String, dynamic> get memberAudioJson {
    final raw = _prefs.getString(_kMemberAudio);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> setMemberAudioJson(Map<String, dynamic> audio) =>
      _prefs.setString(_kMemberAudio, jsonEncode(audio));

  /// The person's vault as this device last merged it (see `Vault`): the
  /// servers they are on and the devices they have paired. None of it is
  /// secret — addresses, public keys and device names — and the copy each
  /// server holds is sealed.
  Map<String, dynamic> get identityVaultJson {
    final raw = _prefs.getString(_kIdentityVault);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> setIdentityVaultJson(Map<String, dynamic> vault) =>
      _prefs.setString(_kIdentityVault, jsonEncode(vault));

  /// Servers removed from *this* device, as `host:port`. The vault still
  /// lists them — removing a server here is not leaving it, and the person's
  /// other devices keep it — so this is what stops the vault putting them
  /// straight back.
  Set<String> get hiddenServers =>
      (_prefs.getStringList(_kHiddenServers) ?? const []).toSet();

  Future<void> setHiddenServers(Set<String> servers) =>
      _prefs.setStringList(_kHiddenServers, servers.toList()..sort());

  /// What this device calls itself in the person's device list.
  String? get deviceName => _prefs.getString(_kDeviceName);

  Future<void> setDeviceName(String name) =>
      _prefs.setString(_kDeviceName, name);

  /// When the current recovery words were shown on this device and the
  /// person confirmed they had written them down.
  DateTime? get recoveryWordsSetAt => _time(_kRecoveryWordsSetAt);

  /// When the person last showed, on this device, that they still have their
  /// recovery words — by confirming new ones or checking the current ones.
  DateTime? get recoveryCheckedAt => _time(_kRecoveryCheckedAt);

  /// New words were confirmed: they were made and checked just now.
  Future<void> recordRecoveryWordsSet(DateTime at) async {
    await _prefs.setInt(_kRecoveryWordsSetAt, at.millisecondsSinceEpoch);
    await _prefs.setInt(_kRecoveryCheckedAt, at.millisecondsSinceEpoch);
  }

  Future<void> recordRecoveryChecked(DateTime at) =>
      _prefs.setInt(_kRecoveryCheckedAt, at.millisecondsSinceEpoch);

  /// When this device's wait to get in without an authenticator code ends,
  /// per server id — for the servers it is waiting on.
  Map<String, DateTime> get recoveryWaits {
    final raw = _prefs.getString(_kRecoveryWaits);
    if (raw == null) return {};
    return {
      for (final entry in (jsonDecode(raw) as Map).entries)
        entry.key as String: DateTime.fromMillisecondsSinceEpoch(
          entry.value as int,
          isUtc: true,
        ),
    };
  }

  Future<void> setRecoveryWait(String serverId, DateTime? eligibleAt) {
    final waits = recoveryWaits;
    if (eligibleAt == null) {
      if (waits.remove(serverId) == null) return Future.value();
    } else {
      waits[serverId] = eligibleAt.toUtc();
    }
    return _prefs.setString(
      _kRecoveryWaits,
      jsonEncode({
        for (final entry in waits.entries)
          entry.key: entry.value.millisecondsSinceEpoch,
      }),
    );
  }

  /// Other devices' recovery waits the person said were theirs, as
  /// `serverId/deviceId`, so they are not asked again.
  Set<String> get acknowledgedRecoveries =>
      (_prefs.getStringList(_kAcknowledgedRecoveries) ?? const []).toSet();

  Future<void> setAcknowledgedRecoveries(Set<String> keys) =>
      _prefs.setStringList(_kAcknowledgedRecoveries, keys.toList()..sort());

  static const _kRecoveryWaits = 'identity.recovery_waits';
  static const _kAcknowledgedRecoveries = 'identity.acknowledged_recoveries';
  static const _kRecoveryWordsSetAt = 'identity.recovery_words_set_at';
  static const _kRecoveryCheckedAt = 'identity.recovery_checked_at';

  DateTime? _time(String key) {
    final ms = _prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
