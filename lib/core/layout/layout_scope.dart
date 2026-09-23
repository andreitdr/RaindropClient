import 'package:flutter/widgets.dart';

import 'layout_config.dart';

/// How a slot draws its buttons: the rail's large round buttons, or the
/// compact icon buttons of a toolbar.
enum SlotStyle { rail, compact }

/// One button that can be placed in a slot. [build] draws the live button in
/// the slot's style; [label] and [icon] are what the layout editor shows.
///
/// Buttons are looked up by [id] in a registry map handed to [LayoutScope],
/// so adding one is adding an entry, not editing a switch.
class LayoutButtonSpec {
  const LayoutButtonSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.build,
  });

  final String id;
  final String label;
  final IconData icon;
  final Widget Function(BuildContext context, SlotStyle style) build;
}

/// A drag in the layout editor: a pane being moved, or a button being moved
/// between slots (or out of the editor's palette, when [fromSlot] is null).
sealed class LayoutDrag {
  const LayoutDrag();
}

class PaneDrag extends LayoutDrag {
  const PaneDrag(this.paneId);

  final String paneId;
}

class ButtonDrag extends LayoutDrag {
  const ButtonDrag(this.buttonId, {this.fromSlot, this.fromIndex});

  final String buttonId;
  final String? fromSlot;
  final int? fromIndex;
}

/// Present only while the layout editor is open: how edits reach its draft,
/// and how it dresses each pane with its handles.
class LayoutEditing {
  const LayoutEditing({
    required this.rules,
    required this.edit,
    required this.decoratePane,
  });

  final LayoutRules rules;

  /// Applies an edit to the editor's current draft. Takes a function rather
  /// than a finished layout, so several pointer events handled before the
  /// next frame each build on the one before.
  final void Function(LayoutConfig Function(LayoutConfig) update) edit;

  final Widget Function(
    BuildContext context,
    PaneLayout pane,
    int index,
    Widget child,
  )
  decoratePane;
}

/// The layout the widgets below it render: the saved one, or the editor's
/// draft when [editing] is set. Lets a slot deep inside a pane find its
/// buttons without every pane threading them through.
class LayoutScope extends InheritedWidget {
  const LayoutScope({
    super.key,
    required this.config,
    required this.buttons,
    this.editing,
    this.collapsedPanes = const {},
    required super.child,
  });

  final LayoutConfig config;
  final Map<String, LayoutButtonSpec> buttons;
  final LayoutEditing? editing;

  /// Panes the layout shows but the window is too narrow for right now.
  final Set<String> collapsedPanes;

  static LayoutScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LayoutScope>();

  static bool isEditing(BuildContext context) =>
      maybeOf(context)?.editing != null;

  /// This scope with [collapsedPanes] replaced, for the part of the tree that
  /// knows the window's width.
  LayoutScope withCollapsed(Set<String> collapsed, {required Widget child}) =>
      LayoutScope(
        config: config,
        buttons: buttons,
        editing: editing,
        collapsedPanes: collapsed,
        child: child,
      );

  @override
  bool updateShouldNotify(LayoutScope oldWidget) =>
      config != oldWidget.config ||
      buttons != oldWidget.buttons ||
      editing != oldWidget.editing ||
      !_sameSet(collapsedPanes, oldWidget.collapsedPanes);

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
