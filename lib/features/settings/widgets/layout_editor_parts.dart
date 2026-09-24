import 'package:flutter/material.dart';

import '../../../core/layout/layout_config.dart';
import '../../../core/layout/layout_edit_barrier.dart';
import '../../../core/layout/layout_scope.dart';
import '../../../core/layout/layout_slot.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/layout/main_layout.dart';

/// The pieces the layout editor is built from: a pane dressed with its
/// handles, and the tray of buttons under the preview. Separate from the
/// screen so they can be driven in a widget test without a live session.

/// One pane in the editor: the live pane made inert (its slots excepted),
/// outlined, with a handle to drag it by (and hide it, where allowed), a
/// drop zone for other panes, and — where it can be resized — a grip on the
/// edge that faces the chat.
///
/// A button dropped anywhere on the pane joins the pane's own toolbar, at the
/// end; dropping onto a slot, or between two of its chips, still places it
/// exactly there. Without that, the only targets are the chips themselves,
/// which is far too fine a thing to aim at — and impossible once a slot has
/// been emptied.
class LayoutPaneEditor extends StatefulWidget {
  const LayoutPaneEditor({
    super.key,
    required this.pane,
    required this.index,
    required this.contentIndex,
    required this.rules,
    required this.edit,
    required this.child,
  });

  final PaneLayout pane;
  final int index;
  final int contentIndex;
  final LayoutRules rules;
  final void Function(LayoutConfig Function(LayoutConfig)) edit;
  final Widget child;

  @override
  State<LayoutPaneEditor> createState() => _LayoutPaneEditorState();
}

class _LayoutPaneEditorState extends State<LayoutPaneEditor> {
  /// The barrier is asked whether a slot is under the pointer, so the
  /// pane-wide drop zone can stand aside for it.
  final _barrierKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final pane = widget.pane;
    final scheme = Theme.of(context).colorScheme;
    final resizable = widget.rules.panes[pane.id]?.resizable ?? false;
    final label = mainPaneLabels[pane.id] ?? pane.id;
    final gripOnRight = widget.index < widget.contentIndex;
    final slot = widget.rules.slotOfPane(pane.id);

    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutEditBarrier(key: _barrierKey, child: widget.child),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.04),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
          ),
        ),
        Center(
          child: _PaneHandle(
            paneId: pane.id,
            label: label,
            compact: (pane.width ?? double.infinity) < 150,
            onHide: widget.rules.canHidePane(pane.id)
                ? () => widget.edit((c) => c.setPaneVisible(pane.id, false))
                : null,
          ),
        ),
        if (resizable)
          Positioned(
            top: 0,
            bottom: 0,
            left: gripOnRight ? null : 0,
            right: gripOnRight ? 0 : null,
            width: 12,
            child: _ResizeGrip(
              paneId: pane.id,
              width: pane.width!,
              growsRight: gripOnRight,
              edit: widget.edit,
            ),
          ),
        // Both drop zones go over the handle and the grip: they take no
        // pointer events of their own while nothing is being dragged, and
        // below those they would lose every drop aimed at the middle of the
        // pane, which is exactly where the handle sits.
        _PaneDropZone(
          paneId: pane.id,
          index: widget.index,
          edit: widget.edit,
        ),
        if (slot != null)
          _PaneButtonDropZone(
            slotId: slot,
            barrierKey: _barrierKey,
            edit: widget.edit,
          ),
      ],
    );
  }
}

/// Takes a button dropped anywhere on the pane and appends it to the pane's
/// toolbar — unless the pointer is over that toolbar itself, where the slot
/// places it exactly instead.
class _PaneButtonDropZone extends StatelessWidget {
  const _PaneButtonDropZone({
    required this.slotId,
    required this.barrierKey,
    required this.edit,
  });

  final String slotId;
  final GlobalKey barrierKey;
  final void Function(LayoutConfig Function(LayoutConfig)) edit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<LayoutDrag>(
      onWillAcceptWithDetails: (details) {
        if (details.data is! ButtonDrag) return false;
        final barrier = barrierKey.currentContext;
        return barrier == null || !layoutSlotUnder(barrier, details.offset);
      },
      onAcceptWithDetails: (details) {
        final drag = details.data as ButtonDrag;
        edit(
          (config) => config.placeButton(
            drag.buttonId,
            slotId: slotId,
            index: config.slot(slotId).length,
            fromSlot: drag.fromSlot,
            fromIndex: drag.fromIndex,
          ),
        );
      },
      builder: (context, candidates, _) => IgnorePointer(
        child: candidates.isEmpty
            ? const SizedBox.expand()
            : ColoredBox(
                color: scheme.primary.withValues(alpha: 0.18),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Material(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Add to this toolbar',
                          style: TextStyle(color: scheme.onPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PaneHandle extends StatelessWidget {
  const _PaneHandle({
    required this.paneId,
    required this.label,
    required this.compact,
    this.onHide,
  });

  final String paneId;
  final String label;
  final bool compact;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip({required bool dragging}) => Material(
      color: scheme.primaryContainer,
      elevation: dragging ? 6 : 2,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_indicator, color: scheme.onPrimaryContainer),
            if (!compact || dragging) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (onHide != null && !dragging)
              IconButton(
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                tooltip: 'Hide $label',
                visualDensity: VisualDensity.compact,
                color: scheme.onPrimaryContainer,
                onPressed: onHide,
              ),
          ],
        ),
      ),
    );

    return Draggable<LayoutDrag>(
      data: PaneDrag(paneId),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: chip(dragging: true),
      childWhenDragging: Opacity(opacity: 0.3, child: chip(dragging: false)),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Tooltip(
          message: 'Drag to move $label',
          child: chip(dragging: false),
        ),
      ),
    );
  }
}

/// Dropping a pane on this one's left half puts it before this one; on the
/// right half, after.
class _PaneDropZone extends StatefulWidget {
  const _PaneDropZone({
    required this.paneId,
    required this.index,
    required this.edit,
  });

  final String paneId;
  final int index;
  final void Function(LayoutConfig Function(LayoutConfig)) edit;

  @override
  State<_PaneDropZone> createState() => _PaneDropZoneState();
}

class _PaneDropZoneState extends State<_PaneDropZone> {
  bool? _before;

  bool _accepts(LayoutDrag drag) =>
      drag is PaneDrag && drag.paneId != widget.paneId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<LayoutDrag>(
      onWillAcceptWithDetails: (details) => _accepts(details.data),
      onMove: (details) {
        if (!_accepts(details.data)) return;
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(details.offset);
        final before = local.dx < box.size.width / 2;
        if (before != _before) setState(() => _before = before);
      },
      onLeave: (_) => setState(() => _before = null),
      onAcceptWithDetails: (details) {
        final drag = details.data as PaneDrag;
        final before = _before ?? true;
        setState(() => _before = null);
        widget.edit(
          (c) => c.movePane(
            drag.paneId,
            before ? widget.index : widget.index + 1,
          ),
        );
      },
      builder: (context, candidates, _) => IgnorePointer(
        child: candidates.isEmpty || _before == null
            ? const SizedBox.expand()
            : Align(
                alignment: _before!
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(width: 4, color: scheme.primary),
              ),
      ),
    );
  }
}

class _ResizeGrip extends StatefulWidget {
  const _ResizeGrip({
    required this.paneId,
    required this.width,
    required this.growsRight,
    required this.edit,
  });

  final String paneId;
  final double width;

  /// The grip is on the pane's right edge, so dragging right widens it.
  final bool growsRight;
  final void Function(LayoutConfig Function(LayoutConfig)) edit;

  @override
  State<_ResizeGrip> createState() => _ResizeGripState();
}

class _ResizeGripState extends State<_ResizeGrip> {
  // Measured from where the drag began, not from the last frame's width: a
  // drag past the limit and back lands where the pointer is.
  double _startWidth = 0;
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _startWidth = widget.width;
          _dx = 0;
        },
        onHorizontalDragUpdate: (details) {
          _dx += details.delta.dx;
          final width = _startWidth + (widget.growsRight ? _dx : -_dx);
          widget.edit((c) => c.resizePane(widget.paneId, width));
        },
        child: Tooltip(
          message: 'Drag to resize',
          child: Center(
            child: Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The strip under the preview: hidden panes to bring back, every button to
/// drag into a toolbar, and the place to drop a button or pane to hide it.
class LayoutEditorTray extends StatelessWidget {
  const LayoutEditorTray({
    super.key,
    required this.draft,
    required this.rules,
    required this.buttons,
    required this.edit,
  });

  final LayoutConfig draft;
  final LayoutRules rules;
  final Map<String, LayoutButtonSpec> buttons;
  final void Function(LayoutConfig Function(LayoutConfig)) edit;

  bool _accepts(LayoutDrag drag) => switch (drag) {
    ButtonDrag(:final fromSlot?, :final fromIndex?) => rules.canRemoveButton(
      draft,
      fromSlot,
      fromIndex,
    ),
    PaneDrag(:final paneId) => rules.canHidePane(paneId),
    _ => false,
  };

  String? _whyNot(Object? drag) => switch (drag) {
    ButtonDrag(fromSlot: _?, :final buttonId)
        when rules.requiredButtons.contains(buttonId) =>
      '${buttons[buttonId]?.label ?? buttonId} has to stay in at least one '
          'toolbar: this editor is reached through it.',
    PaneDrag(:final paneId) =>
      '${mainPaneLabels[paneId] ?? paneId} can be moved but not hidden.',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hidden = draft.panes.where((p) => !p.visible).toList();

    return DragTarget<LayoutDrag>(
      onWillAcceptWithDetails: (details) => _accepts(details.data),
      onAcceptWithDetails: (details) => edit(
        (c) => switch (details.data) {
          ButtonDrag(:final fromSlot?, :final fromIndex?) => c.removeButton(
            fromSlot,
            fromIndex,
          ),
          PaneDrag(:final paneId) => c.setPaneVisible(paneId, false),
          _ => c,
        },
      ),
      builder: (context, candidates, rejected) {
        final why = rejected.map(_whyNot).nonNulls.firstOrNull;
        final hint =
            why ??
            (candidates.isNotEmpty
                ? 'Drop here to hide it.'
                : 'Drag panes by their handle and buttons by their chip. '
                      'Drop a button anywhere on a pane to add it to that '
                      "pane's toolbar, or onto a chip to place it exactly. "
                      'Drop one here to remove it.');
        return Material(
          color: candidates.isNotEmpty
              ? theme.colorScheme.primaryContainer
              : context.surfaces.raised,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: why != null
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final pane in hidden)
                        ActionChip(
                          avatar: const Icon(Icons.visibility_outlined),
                          label: Text(
                            'Show ${mainPaneLabels[pane.id] ?? pane.id}',
                          ),
                          onPressed: () =>
                              edit((c) => c.setPaneVisible(pane.id, true)),
                        ),
                      for (final spec in buttons.values)
                        _PaletteButton(
                          chip: LayoutButtonChip(
                            icon: spec.icon,
                            label: spec.label,
                            showLabel: true,
                          ),
                          drag: ButtonDrag(spec.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({required this.chip, required this.drag});

  final LayoutButtonChip chip;
  final ButtonDrag drag;

  @override
  Widget build(BuildContext context) {
    return Draggable<LayoutDrag>(
      data: drag,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: chip,
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: chip),
    );
  }
}
