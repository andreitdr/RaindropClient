import 'dart:convert';

/// The version of the layout file this build writes. A file with a higher
/// version is still read — every field is optional and unknown ids are kept —
/// and is rewritten at this version the next time the layout is saved.
const kLayoutFormatVersion = 1;

/// One pane of the main view's row: which one ([id]), how wide it is, and
/// whether the user has hidden it. A pane with a null [width] fills whatever
/// the fixed panes leave over.
class PaneLayout {
  const PaneLayout({required this.id, this.width, this.visible = true});

  final String id;
  final double? width;
  final bool visible;

  PaneLayout copyWith({double? width, bool? visible}) => PaneLayout(
    id: id,
    width: width ?? this.width,
    visible: visible ?? this.visible,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (width != null) 'width': width,
    'visible': visible,
  };

  factory PaneLayout.fromJson(Object? json) {
    if (json case {'id': final String id}) {
      final width = json['width'];
      final visible = json['visible'];
      return PaneLayout(
        id: id,
        width: width is num ? width.toDouble() : null,
        visible: visible is bool ? visible : true,
      );
    }
    throw const FormatException('A pane needs a string "id".');
  }

  @override
  bool operator ==(Object other) =>
      other is PaneLayout &&
      other.id == id &&
      other.width == width &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(id, width, visible);
}

/// What a pane may do: whether it can be hidden, whether it fills the
/// leftover space, and how far it can be resized. A pane that neither fills
/// nor has a `[minWidth, maxWidth]` range keeps its default width.
class PaneRule {
  const PaneRule({
    this.required = false,
    this.fill = false,
    this.slot,
    this.minWidth,
    this.maxWidth,
  });

  /// Required panes can be moved but never hidden.
  final bool required;

  /// The pane that takes the space left over (the chat); never resized.
  final bool fill;

  /// The toolbar inside this pane: where a button dropped anywhere on it
  /// goes. Null for a pane with no toolbar of its own.
  final String? slot;

  final double? minWidth;
  final double? maxWidth;

  bool get resizable =>
      !fill && minWidth != null && maxWidth != null && minWidth! < maxWidth!;
}

/// The constraints a [LayoutConfig] is held to. Supplied by the feature that
/// owns the view (see `features/home/layout/main_layout.dart`), so this file
/// knows panes and buttons only as open strings.
class LayoutRules {
  const LayoutRules({
    required this.defaults,
    required this.panes,
    this.requiredButtons = const {},
  });

  /// The stock layout: what a fresh install shows, what "Reset to default"
  /// goes back to, and where a pane or slot missing from a file comes from.
  final LayoutConfig defaults;

  final Map<String, PaneRule> panes;

  /// Buttons that must sit in at least one slot — Settings, since the layout
  /// editor itself is reached through it.
  final Set<String> requiredButtons;

  /// Whether taking the button at [index] out of [slotId] would leave a
  /// required button with nowhere to live.
  bool canRemoveButton(LayoutConfig config, String slotId, int index) {
    final slot = config.slot(slotId);
    if (index < 0 || index >= slot.length) return false;
    final id = slot[index];
    if (!requiredButtons.contains(id)) return true;
    return config.buttonCount(id) > 1;
  }

  bool canHidePane(String paneId) => panes[paneId]?.required != true;

  /// The toolbar a button dropped on [paneId] belongs in, if it has one.
  String? slotOfPane(String paneId) => panes[paneId]?.slot;
}

/// How the main view is arranged: its panes in left-to-right order, and which
/// buttons sit in which slot (a toolbar inside a pane, such as the rail's
/// footer). Plain JSON on disk — see `LayoutStore`.
///
/// Ids are open strings. One this build does not know is kept, not dropped,
/// so a file written by a newer build (or, later, a plugin) survives being
/// saved by this one; it just renders as nothing.
class LayoutConfig {
  const LayoutConfig({
    this.version = kLayoutFormatVersion,
    required this.panes,
    required this.slots,
  });

  final int version;
  final List<PaneLayout> panes;
  final Map<String, List<String>> slots;

  PaneLayout? pane(String id) {
    for (final pane in panes) {
      if (pane.id == id) return pane;
    }
    return null;
  }

  List<String> slot(String id) => slots[id] ?? const [];

  /// How many slots [buttonId] appears in.
  int buttonCount(String buttonId) =>
      slots.values.where((ids) => ids.contains(buttonId)).length;

  LayoutConfig copyWith({
    List<PaneLayout>? panes,
    Map<String, List<String>>? slots,
  }) => LayoutConfig(
    version: kLayoutFormatVersion,
    panes: panes ?? this.panes,
    slots: slots ?? this.slots,
  );

  // ── Edits (pure; the editor runs every result through [normalize]) ──────

  /// Moves [paneId] so it lands before whatever is now at [toIndex] (or at
  /// the end, for `panes.length`).
  LayoutConfig movePane(String paneId, int toIndex) {
    final from = panes.indexWhere((p) => p.id == paneId);
    if (from == -1) return this;
    final list = [...panes];
    final moving = list.removeAt(from);
    final to = (from < toIndex ? toIndex - 1 : toIndex).clamp(0, list.length);
    list.insert(to, moving);
    return copyWith(panes: list);
  }

  LayoutConfig resizePane(String paneId, double width) => copyWith(
    panes: [
      for (final p in panes) p.id == paneId ? p.copyWith(width: width) : p,
    ],
  );

  LayoutConfig setPaneVisible(String paneId, bool visible) => copyWith(
    panes: [
      for (final p in panes) p.id == paneId ? p.copyWith(visible: visible) : p,
    ],
  );

  /// Puts [buttonId] into [slotId] at [index]. With [fromSlot]/[fromIndex]
  /// it is a move (taken out of where it was); without, a copy from the
  /// palette. A slot never holds the same button twice, so dropping one
  /// where it already is just reorders it.
  LayoutConfig placeButton(
    String buttonId, {
    required String slotId,
    required int index,
    String? fromSlot,
    int? fromIndex,
  }) {
    final next = {for (final e in slots.entries) e.key: [...e.value]};
    var at = index;
    if (fromSlot != null && fromIndex != null) {
      final source = next[fromSlot];
      if (source != null &&
          fromIndex >= 0 &&
          fromIndex < source.length &&
          source[fromIndex] == buttonId) {
        source.removeAt(fromIndex);
        if (fromSlot == slotId && fromIndex < at) at--;
      }
    }
    final target = next.putIfAbsent(slotId, () => []);
    final existing = target.indexOf(buttonId);
    if (existing != -1) {
      target.removeAt(existing);
      if (existing < at) at--;
    }
    target.insert(at.clamp(0, target.length), buttonId);
    return copyWith(slots: next);
  }

  LayoutConfig removeButton(String slotId, int index) {
    final slot = this.slot(slotId);
    if (index < 0 || index >= slot.length) return this;
    return copyWith(slots: {...slots, slotId: [...slot]..removeAt(index)});
  }

  // ── Validation ──────────────────────────────────────────────────────────

  /// The one place a layout is made valid — on load, on import, after every
  /// edit and before saving — so nothing downstream has to cope with a bad
  /// one:
  ///
  /// - a pane listed twice keeps its first position;
  /// - a pane the defaults have but this layout lacks is put back where the
  ///   defaults have it (a slot likewise gets the default buttons);
  /// - widths are clamped to the pane's range, or reset where it has none;
  /// - required panes are made visible again;
  /// - a slot never lists a button twice;
  /// - a required button that is in no slot goes back to its default slot.
  ///
  /// Unknown panes, slots and buttons are left alone.
  LayoutConfig normalize(LayoutRules rules) {
    final defaults = rules.defaults;
    final seen = <String>{};
    final result = <PaneLayout>[];
    for (final pane in panes) {
      if (!seen.add(pane.id)) continue;
      result.add(_fit(pane, rules));
    }
    for (var i = 0; i < defaults.panes.length; i++) {
      final pane = defaults.panes[i];
      if (seen.contains(pane.id)) continue;
      // Just after the pane it follows by default, so a missing pane comes
      // back next to the neighbour it had.
      final before = i == 0
          ? -1
          : result.indexWhere((p) => p.id == defaults.panes[i - 1].id);
      result.insert(before + 1, _fit(pane, rules));
      seen.add(pane.id);
    }

    final nextSlots = <String, List<String>>{
      for (final e in slots.entries) e.key: e.value.toSet().toList(),
    };
    for (final e in defaults.slots.entries) {
      nextSlots.putIfAbsent(e.key, () => [...e.value]);
    }
    for (final button in rules.requiredButtons) {
      if (nextSlots.values.any((ids) => ids.contains(button))) continue;
      final home = defaults.slots.entries
          .where((e) => e.value.contains(button))
          .map((e) => e.key)
          .firstOrNull;
      if (home != null) nextSlots[home]!.add(button);
    }

    return LayoutConfig(panes: result, slots: nextSlots);
  }

  PaneLayout _fit(PaneLayout pane, LayoutRules rules) {
    final rule = rules.panes[pane.id];
    if (rule == null) return pane;
    final fallback = rules.defaults.pane(pane.id)?.width;
    final double? width;
    if (rule.fill) {
      width = null;
    } else if (rule.resizable) {
      final wanted = pane.width != null && pane.width!.isFinite
          ? pane.width!
          : (fallback ?? rule.minWidth!);
      width = wanted.clamp(rule.minWidth!, rule.maxWidth!).toDouble();
    } else {
      width = fallback;
    }
    return PaneLayout(
      id: pane.id,
      width: width,
      visible: rule.required || pane.visible,
    );
  }

  // ── JSON ────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'version': version,
    'panes': [for (final p in panes) p.toJson()],
    'slots': slots,
  };

  /// Reads a layout, throwing a [FormatException] when the shape is wrong.
  /// Fields it does not recognise are ignored; missing ones are filled in by
  /// [normalize].
  factory LayoutConfig.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('A layout is a JSON object.');
    }
    final version = json['version'];
    final panes = json['panes'] ?? const [];
    final slots = json['slots'] ?? const {};
    if (panes is! List) {
      throw const FormatException('"panes" must be a list.');
    }
    if (slots is! Map) {
      throw const FormatException('"slots" must be an object.');
    }
    return LayoutConfig(
      version: version is int ? version : kLayoutFormatVersion,
      panes: [for (final p in panes) PaneLayout.fromJson(p)],
      slots: {
        for (final e in slots.entries)
          if (e.key is String)
            e.key as String: switch (e.value) {
              final List ids => [
                for (final id in ids)
                  if (id is String) id,
              ],
              _ => throw FormatException('Slot "${e.key}" must be a list.'),
            },
      },
    );
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static LayoutConfig decode(String source) =>
      LayoutConfig.fromJson(jsonDecode(source));

  @override
  bool operator ==(Object other) {
    if (other is! LayoutConfig ||
        other.panes.length != panes.length ||
        other.slots.length != slots.length) {
      return false;
    }
    for (var i = 0; i < panes.length; i++) {
      if (other.panes[i] != panes[i]) return false;
    }
    for (final e in slots.entries) {
      final theirs = other.slots[e.key];
      if (theirs == null || theirs.length != e.value.length) return false;
      for (var i = 0; i < theirs.length; i++) {
        if (theirs[i] != e.value[i]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(panes),
    Object.hashAllUnordered(
      slots.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value))),
    ),
  );
}
