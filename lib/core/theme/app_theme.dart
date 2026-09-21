import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Turns one [AppThemeDefinition]'s raw colors into a full [ThemeData]. This
/// is the only place Material component theming (app bar, cards, inputs,
/// dividers) is defined, so every theme — built-in or user-created — gets
/// identical component styling and differs only in the colors it supplies.
class AppTheme {
  AppTheme._();

  static ThemeData build({
    required Brightness brightness,
    required Color seedColor,
    required AppSurfaces surfaces,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaces.chat,
      extensions: [surfaces],
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaces.sidebar,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaces.rail,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
      ),
      cardTheme: CardThemeData(
        color: surfaces.raised,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.raised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
