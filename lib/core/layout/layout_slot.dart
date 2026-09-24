import 'package:flutter/material.dart';

import 'layout_edit_barrier.dart';
import 'layout_scope.dart';

/// A toolbar inside a pane whose buttons come from the layout: the rail's
/// footer, the user panel, the chat's top bar. Draws the buttons the nearest
/// [LayoutScope] lists for [slotId], skipping ids it has no button for; in the
/// layout editor, draws them as chips that can be dragged to another slot,
/// reordered, or dragged off to hide.
class LayoutSlot extends StatelessWidget {
  const LayoutSlot(
    this.slotId, {
    super.key,
    this.style = SlotStyle.compact,
    this.axis = Axis.horizontal,
    this.spacing = 0,
  });

  final String slotId;
  final SlotStyle style;
  final Axis axis;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final scope = LayoutScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    final ids = scope.config.slot(slotId);

    final editing = scope.editing;
    if (editing != null) {
      return LayoutHitThrough(
        child: _EditableSlot(
          slotId: slotId,
          ids: ids,
          buttons: scope.buttons,
          editing: editing,
          style: style,
          axis: axis,
        ),
      );
    }

    return Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: [
        for (final id in ids)
          if (scope.buttons[id] case final spec?) spec.build(context, style),
      ],
    );
  }
}

class _EditableSlot extends StatelessWidget {
  const _EditableSlot({
    required this.slotId,
    required this.ids,
    required this.buttons,
    required this.editing,
    required this.style,
    required this.axis,
  });

  final String slotId;
  final List<String> ids;
  final Map<String, LayoutButtonSpec> buttons;
  final LayoutEditing editing;
  final SlotStyle style;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chipSize = style == SlotStyle.rail ? 52.0 : 32.0;
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < ids.length; i++)
            _SlotDropTarget(
              slotId: slotId,
              index: i,
              axis: axis,
              editing: editing,
              child: _SlotChip(
                drag: ButtonDrag(ids[i], fromSlot: slotId, fromIndex: i),
                chip: LayoutButtonChip.forId(
                  ids[i],
                  buttons,
                  size: chipSize,
                ),
                padding: style == SlotStyle.rail
                    ? const EdgeInsets.symmetric(vertical: 4)
                    : const EdgeInsets.all(2),
              ),
            ),
          // The end of the slot, and all of an empty one — which says so,
          // since an empty toolbar is otherwise an invisible target.
          _SlotDropTarget(
            slotId: slotId,
            index: ids.length,
            axis: axis,
            editing: editing,
            child: ids.isEmpty
                ? SizedBox.square(
                    dimension: chipSize,
                    child: Icon(
                      Icons.add,
                      size: chipSize * 0.5,
                      color: scheme.primary,
                    ),
                  )
                : const SizedBox.square(dimension: 20),
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.drag,
    required this.chip,
    required this.padding,
  });

  final ButtonDrag drag;
  final LayoutButtonChip chip;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Draggable<LayoutDrag>(
        data: drag,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: chip,
        childWhenDragging: Opacity(opacity: 0.3, child: chip),
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Tooltip(message: chip.label, child: chip),
        ),
      ),
    );
  }
}

/// Dropping a button here puts it at [index] of [slotId] — before the chip
/// this wraps. Shows a bar on that edge while a button hovers over it.
class _SlotDropTarget extends StatelessWidget {
  const _SlotDropTarget({
    required this.slotId,
    required this.index,
    required this.axis,
    required this.editing,
    required this.child,
  });

  final String slotId;
  final int index;
  final Axis axis;
  final LayoutEditing editing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<LayoutDrag>(
      onWillAcceptWithDetails: (details) => details.data is ButtonDrag,
      onAcceptWithDetails: (details) {
        final drag = details.data as ButtonDrag;
        editing.edit(
          (config) => config.placeButton(
            drag.buttonId,
            slotId: slotId,
            index: index,
            fromSlot: drag.fromSlot,
            fromIndex: drag.fromIndex,
          ),
        );
      },
      builder: (context, candidates, _) {
        if (candidates.isEmpty) return child;
        final bar = BorderSide(color: scheme.primary, width: 3);
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: axis == Axis.horizontal
                ? Border(left: bar)
                : Border(top: bar),
          ),
          child: child,
        );
      },
    );
  }
}

/// How the layout editor draws a button: its icon on a tinted round tile, and
/// its label beside it when [showLabel] is set (the editor's palette).
class LayoutButtonChip extends StatelessWidget {
  const LayoutButtonChip({
    super.key,
    required this.icon,
    required this.label,
    this.size = 32,
    this.showLabel = false,
  });

  /// The chip for [id] — a generic one when this build has no such button
  /// (a layout from a newer build), so it can still be moved or removed.
  factory LayoutButtonChip.forId(
    String id,
    Map<String, LayoutButtonSpec> buttons, {
    double size = 32,
    bool showLabel = false,
  }) {
    final spec = buttons[id];
    return LayoutButtonChip(
      icon: spec?.icon ?? Icons.extension_outlined,
      label: spec?.label ?? id,
      size: size,
      showLabel: showLabel,
    );
  }

  final IconData icon;
  final String label;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      shape: const StadiumBorder(),
      elevation: 1,
      child: SizedBox(
        height: size,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: showLabel ? null : size,
                child: Icon(
                  icon,
                  size: size * 0.55,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
