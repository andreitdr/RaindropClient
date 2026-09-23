import 'package:flutter/widgets.dart';

import 'layout_config.dart';
import 'layout_scope.dart';

/// The main view's row of panes, in the order and at the widths the nearest
/// [LayoutScope] gives. A pane with a width gets exactly that; the one
/// without fills the rest.
///
/// [paneBuilder] returns null for a pane it cannot draw here — an id this
/// build does not know, or one this screen does not have — and that pane is
/// skipped. [omit] leaves out panes the window has no room for right now.
///
/// In the layout editor each pane is dressed by `LayoutEditing.decoratePane`,
/// and a window too narrow for the whole layout is scaled down to fit rather
/// than squeezing the filling pane to nothing.
class LayoutRow extends StatelessWidget {
  const LayoutRow({
    super.key,
    required this.paneBuilder,
    this.omit = const {},
  });

  final Widget? Function(BuildContext context, PaneLayout pane) paneBuilder;
  final Set<String> omit;

  /// The narrowest the filling pane is drawn at in the editor's preview.
  static const editorMinFillWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    final scope = LayoutScope.maybeOf(context)!;
    final editing = scope.editing;
    final panes = scope.config.panes;

    var fixedWidth = 0.0;
    final children = <Widget>[];
    for (var i = 0; i < panes.length; i++) {
      final pane = panes[i];
      if (!pane.visible || omit.contains(pane.id)) continue;
      var child = paneBuilder(context, pane);
      if (child == null) continue;
      if (editing != null) {
        child = editing.decoratePane(context, pane, i, child);
      }
      final width = pane.width;
      if (width == null) {
        children.add(Expanded(child: child));
      } else {
        fixedWidth += width;
        children.add(SizedBox(width: width, child: child));
      }
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (editing == null) return row;

    return LayoutBuilder(
      builder: (context, constraints) {
        final needed = fixedWidth + editorMinFillWidth;
        if (constraints.maxWidth >= needed) return row;
        final scale = constraints.maxWidth / needed;
        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: needed,
            height: constraints.maxHeight / scale,
            child: row,
          ),
        );
      },
    );
  }
}
