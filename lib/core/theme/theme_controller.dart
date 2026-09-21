import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_prefs.dart';
import 'theme_definition.dart';

/// Overridden in `main.dart` once `SharedPreferences` has loaded. Every
/// other prefs-backed provider in the app reads through this one so there's
/// a single init point.
final appPrefsProvider = Provider<AppPrefs>((ref) {
  throw UnimplementedError(
    'appPrefsProvider must be overridden in main() before runApp',
  );
});

/// The two shipped themes, loaded from `assets/themes/*.json` once at
/// startup and overridden in `main.dart` — mirrors [appPrefsProvider]'s
/// "load once before runApp" pattern, since asset loading is async and a
/// [Notifier.build] isn't.
final builtInThemesProvider = Provider<List<AppThemeDefinition>>((ref) {
  throw UnimplementedError(
    'builtInThemesProvider must be overridden in main() before runApp',
  );
});

/// Every theme available to pick from: the two built-in ones plus whatever
/// the user has created. Adding, editing, and deleting all go through this
/// controller so the persisted copy in [AppPrefs.customThemesJson] never
/// drifts from what's shown in the theme selector.
final themeCatalogProvider =
    NotifierProvider<ThemeCatalogController, List<AppThemeDefinition>>(
      ThemeCatalogController.new,
    );

class ThemeCatalogController extends Notifier<List<AppThemeDefinition>> {
  @override
  List<AppThemeDefinition> build() {
    final builtIn = ref.read(builtInThemesProvider);
    final custom = ref
        .read(appPrefsProvider)
        .customThemesJson
        .map((json) => AppThemeDefinition.fromJson(json))
        .toList();
    return [...builtIn, ...custom];
  }

  /// Saves a custom theme, replacing any existing one with the same id.
  /// Refuses to touch a built-in theme's id — the editor always assigns a
  /// fresh id when it starts from one, so this should never be hit, but
  /// it's the invariant this controller exists to protect.
  void addOrUpdate(AppThemeDefinition theme) {
    if (theme.isBuiltIn) return;
    final others = state.where((t) => t.id != theme.id).toList();
    state = [...others, theme];
    _persistCustom();
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
    _persistCustom();
  }

  void _persistCustom() {
    final custom = state
        .where((t) => !t.isBuiltIn)
        .map((t) => t.toJson())
        .toList();
    ref.read(appPrefsProvider).setCustomThemesJson(custom);
  }
}

/// The id of whichever theme is currently selected: `kSystemThemeId`, a
/// built-in id, or a custom theme's id. Resolving this to an actual
/// [AppThemeDefinition] (handling `kSystemThemeId` and a deleted custom
/// theme) is [resolveActiveTheme]'s job, not this controller's.
final activeThemeIdProvider = NotifierProvider<ActiveThemeIdController, String>(
  ActiveThemeIdController.new,
);

class ActiveThemeIdController extends Notifier<String> {
  @override
  String build() => ref.read(appPrefsProvider).activeThemeId;

  void select(String id) {
    state = id;
    ref.read(appPrefsProvider).setActiveThemeId(id);
  }
}

/// Turns the selected theme id into the [AppThemeDefinition] to actually
/// render. `kSystemThemeId` resolves to the built-in `light` or `dark`
/// theme based on [platformBrightness]; anything else looks itself up in
/// [catalog], falling back to `light` if it was deleted out from under an
/// active selection (e.g. this theme was removed on another install that
/// shares the same synced prefs).
AppThemeDefinition resolveActiveTheme({
  required String activeId,
  required List<AppThemeDefinition> catalog,
  required Brightness platformBrightness,
}) {
  final wantId = activeId == kSystemThemeId
      ? (platformBrightness == Brightness.dark ? 'dark' : 'light')
      : activeId;
  for (final theme in catalog) {
    if (theme.id == wantId) return theme;
  }
  for (final theme in catalog) {
    if (theme.id == 'light') return theme;
  }
  return catalog.first;
}
