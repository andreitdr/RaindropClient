import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_colors.dart';
import 'app_theme.dart';

/// One theme, built-in or user-created: a name, a brightness, an accent
/// ([seedColor] that [ColorScheme.fromSeed] derives every Material color
/// role from), and the [AppSurfaces] tier colors. This is the one format
/// both the bundled `assets/themes/*.json` files and a user's custom themes
/// (persisted via [AppPrefs.customThemesJson]) serialize to and from — a
/// theme is "just JSON" all the way through, which is what makes swapping or
/// adding one a matter of editing/writing a JSON object rather than Dart.
class AppThemeDefinition {
  const AppThemeDefinition({
    required this.id,
    required this.name,
    required this.brightness,
    required this.seedColor,
    required this.surfaces,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final Color seedColor;
  final AppSurfaces surfaces;

  /// True for the two shipped themes (`light`, `dark`). Built-in themes
  /// can be selected and used as a starting point for a copy, but can't be
  /// edited or deleted in place — the theme editor always saves those
  /// changes as a new custom theme.
  final bool isBuiltIn;

  ThemeData toThemeData() => AppTheme.build(
    brightness: brightness,
    seedColor: seedColor,
    surfaces: surfaces,
  );

  AppThemeDefinition copyWith({
    String? id,
    String? name,
    Brightness? brightness,
    Color? seedColor,
    AppSurfaces? surfaces,
    bool? isBuiltIn,
  }) {
    return AppThemeDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      seedColor: seedColor ?? this.seedColor,
      surfaces: surfaces ?? this.surfaces,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  factory AppThemeDefinition.fromJson(
    Map<String, dynamic> json, {
    bool isBuiltIn = false,
  }) {
    final surfacesJson = json['surfaces'] as Map<String, dynamic>;
    return AppThemeDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      brightness: json['brightness'] == 'dark'
          ? Brightness.dark
          : Brightness.light,
      seedColor: _colorFromHex(json['seedColor'] as String),
      surfaces: AppSurfaces(
        rail: _colorFromHex(surfacesJson['rail'] as String),
        sidebar: _colorFromHex(surfacesJson['sidebar'] as String),
        chat: _colorFromHex(surfacesJson['chat'] as String),
        raised: _colorFromHex(surfacesJson['raised'] as String),
        onlineIndicator: _colorFromHex(
          surfacesJson['onlineIndicator'] as String,
        ),
      ),
      isBuiltIn: isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brightness': brightness == Brightness.dark ? 'dark' : 'light',
    'seedColor': _colorToHex(seedColor),
    'surfaces': {
      'rail': _colorToHex(surfaces.rail),
      'sidebar': _colorToHex(surfaces.sidebar),
      'chat': _colorToHex(surfaces.chat),
      'raised': _colorToHex(surfaces.raised),
      'onlineIndicator': _colorToHex(surfaces.onlineIndicator),
    },
  };

  @override
  bool operator ==(Object other) =>
      other is AppThemeDefinition && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The two themes Raindrop ships, loaded once at startup from
/// `assets/themes/*.json` and handed to the app via `builtInThemesProvider`
/// (see `theme_controller.dart`) — the same "load once before runApp"
/// pattern `AppPrefs` uses for `SharedPreferences`.
Future<List<AppThemeDefinition>> loadBuiltInThemes() async {
  final light = await _loadThemeAsset('assets/themes/light.json');
  final dark = await _loadThemeAsset('assets/themes/dark.json');
  return [light, dark];
}

Future<AppThemeDefinition> _loadThemeAsset(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  return AppThemeDefinition.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
    isBuiltIn: true,
  );
}

Color _colorFromHex(String hex) {
  var h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

String _colorToHex(Color color) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
  return '#${argb.substring(2).toUpperCase()}';
}
