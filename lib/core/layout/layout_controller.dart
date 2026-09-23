import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'layout_config.dart';
import 'layout_store.dart';

/// Overridden in `main.dart` — the same "load before runApp" pattern as
/// `appPrefsProvider`, since opening the file is async and [Notifier.build]
/// is not.
final layoutStoreProvider = Provider<LayoutStore>((ref) {
  throw UnimplementedError(
    'layoutStoreProvider must be overridden in main() before runApp',
  );
});

/// The layout read from disk at startup, or null for "none saved".
final initialLayoutProvider = Provider<LayoutConfig?>((ref) {
  throw UnimplementedError(
    'initialLayoutProvider must be overridden in main() before runApp',
  );
});

/// The rules (and default layout) of the view being laid out. Overridden in
/// `main.dart` with `mainLayoutRules` from `features/home/layout/`: core knows
/// the format, the feature knows the panes and buttons.
final layoutRulesProvider = Provider<LayoutRules>((ref) {
  throw UnimplementedError(
    'layoutRulesProvider must be overridden in main() before runApp',
  );
});

/// The layout the main view renders. Saving and resetting go through here so
/// the file and what is on screen never disagree.
final layoutConfigProvider = NotifierProvider<LayoutController, LayoutConfig>(
  LayoutController.new,
);

class LayoutController extends Notifier<LayoutConfig> {
  @override
  LayoutConfig build() {
    final rules = ref.watch(layoutRulesProvider);
    return (ref.read(initialLayoutProvider) ?? rules.defaults).normalize(
      rules,
    );
  }

  /// Writes [config] and applies it. A layout equal to the default one is
  /// not written — the file is removed instead, so "no file" keeps meaning
  /// "default", and a later build's new default reaches this install.
  Future<void> save(LayoutConfig config) async {
    final rules = ref.read(layoutRulesProvider);
    final layout = config.normalize(rules);
    final store = ref.read(layoutStoreProvider);
    if (layout == rules.defaults.normalize(rules)) {
      await store.delete();
    } else {
      await store.save(layout);
    }
    state = layout;
  }
}

/// Panes the window is currently too narrow for that the user has asked to
/// see anyway (the Members button). Not saved: it is about this window, now.
final revealedPanesProvider =
    NotifierProvider<RevealedPanesController, Set<String>>(
      RevealedPanesController.new,
    );

class RevealedPanesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String paneId) {
    state = state.contains(paneId)
        ? ({...state}..remove(paneId))
        : {...state, paneId};
  }
}
