import 'package:flutter/material.dart';

/// Fallback brand seed used only when constructing a brand-new custom theme
/// in the theme editor before the user has picked their own accent color.
/// Every shipped or user-created theme carries its own [seedColor] instead
/// of relying on this — see `core/theme/theme_definition.dart`.
const Color raindropSeed = Color(0xFF4C6FFF);

/// Background tiers used by the Discord-style three-pane layout, independent
/// of Material's ColorScheme surface roles so the rail/sidebar/chat panes can
/// step in darkness the way a chat client's do. One instance of this lives
/// inside every [AppThemeDefinition] and is what a theme JSON file's
/// `surfaces` object deserializes into.
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.rail,
    required this.sidebar,
    required this.chat,
    required this.raised,
    required this.onlineIndicator,
  });

  final Color rail;
  final Color sidebar;
  final Color chat;
  final Color raised;
  final Color onlineIndicator;

  static const dark = AppSurfaces(
    rail: Color(0xFF16171F),
    sidebar: Color(0xFF1C1E29),
    chat: Color(0xFF23252F),
    raised: Color(0xFF2B2D3A),
    onlineIndicator: Color(0xFF3BD16F),
  );

  static const light = AppSurfaces(
    rail: Color(0xFFE7E9F5),
    sidebar: Color(0xFFF1F2FA),
    chat: Color(0xFFFAFAFF),
    raised: Color(0xFFFFFFFF),
    onlineIndicator: Color(0xFF2FB765),
  );

  @override
  AppSurfaces copyWith({
    Color? rail,
    Color? sidebar,
    Color? chat,
    Color? raised,
    Color? onlineIndicator,
  }) {
    return AppSurfaces(
      rail: rail ?? this.rail,
      sidebar: sidebar ?? this.sidebar,
      chat: chat ?? this.chat,
      raised: raised ?? this.raised,
      onlineIndicator: onlineIndicator ?? this.onlineIndicator,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      rail: Color.lerp(rail, other.rail, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      chat: Color.lerp(chat, other.chat, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      onlineIndicator: Color.lerp(onlineIndicator, other.onlineIndicator, t)!,
    );
  }
}

extension AppSurfacesX on BuildContext {
  AppSurfaces get surfaces => Theme.of(this).extension<AppSurfaces>()!;
}
