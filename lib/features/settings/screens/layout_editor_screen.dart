import 'dart:io';

import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/layout_config.dart';
import '../../../core/layout/layout_controller.dart';
import '../../../core/layout/layout_edit_barrier.dart';
import '../../../core/layout/layout_scope.dart';
import '../../../core/layout/layout_slot.dart';
import '../../../core/layout/layout_store.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/adaptive.dart';
import '../../home/layout/main_layout.dart';
import '../../home/screens/home_shell.dart';
import '../../servers/controllers/servers_controller.dart';

/// Below this width the main view is the narrow drawer layout, which the
/// saved layout does not arrange — so there is nothing to edit.
const kLayoutEditorMinWidth = 680.0;

const _layoutFileTypes = [
  selector.XTypeGroup(
    label: 'Raindrop layout',
    extensions: ['json'],
    uniformTypeIdentifiers: ['public.json'],
  ),
];

/// Settings → Customize layout: the main view as a live preview, with
/// handles to move and resize its panes and chips to move its buttons
/// between toolbars. Works on a draft; nothing is written until Save.
class LayoutEditorScreen extends ConsumerStatefulWidget {
  const LayoutEditorScreen({super.key});

  @override
  ConsumerState<LayoutEditorScreen> createState() => _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends ConsumerState<LayoutEditorScreen> {
  late LayoutConfig _draft = ref.read(layoutConfigProvider);
  bool _saving = false;

  LayoutRules get _rules => ref.read(layoutRulesProvider);

  void _edit(LayoutConfig Function(LayoutConfig) update) =>
      setState(() => _draft = update(_draft).normalize(_rules));

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(layoutConfigProvider.notifier).save(_draft);
      if (mounted) Navigator.of(context).pop();
    } on FileSystemException catch (e) {
      _say('Could not save the layout: ${e.message}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _import() async {
    final file = await selector.openFile(acceptedTypeGroups: _layoutFileTypes);
    if (file == null) return;
    try {
      final imported = await LayoutStore.readFrom(file.path);
      _edit((_) => imported);
      _say('Layout imported. Save to keep it.');
    } on FormatException {
      _say('That file is not a Raindrop layout.');
    } on FileSystemException catch (e) {
      _say('Could not read that file: ${e.message}');
    }
  }

  Future<void> _export() async {
    final location = await selector.getSaveLocation(
      suggestedName: 'raindrop-layout.json',
      acceptedTypeGroups: _layoutFileTypes,
    );
    if (location == null) return;
    try {
      await LayoutStore.writeTo(location.path, _draft);
      _say('Layout exported.');
    } on FileSystemException catch (e) {
      _say('Could not write that file: ${e.message}');
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showAdaptiveConfirm(
      context,
      title: 'Discard your changes?',
      message: 'The layout stays as it was before you opened the editor.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(layoutConfigProvider);
    final dirty = _draft != saved;
    final isDefault = _draft == _rules.defaults.normalize(_rules);
    final hasServers = ref.watch(serversControllerProvider).isNotEmpty;

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Customize layout'),
          actions: [
            TextButton(
              onPressed: isDefault ? null : () => _edit((_) => _rules.defaults),
              child: const Text('Reset to default'),
            ),
            // Export needs a save dialog, which phones do not have; and the
            // layout only arranges the wide view anyway.
            if (isDesktopPlatform) ...[
              TextButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.file_open_outlined, size: 18),
                label: const Text('Import…'),
              ),
              TextButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text('Export…'),
              ),
            ],
            const SizedBox(width: 8),
            FilledButton(
              onPressed: dirty && !_saving ? _save : null,
              child: const Text('Save'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < kLayoutEditorMinWidth) {
              return const _EditorMessage(
                'Widen the window to edit the layout. It arranges the '
                'wide view; narrow windows and phones keep their own.',
              );
            }
            if (!hasServers) {
              return const _EditorMessage(
                'Connect to a server first: the layout is edited on a '
                'preview of the main view.',
              );
            }
            final editing = LayoutEditing(
              rules: _rules,
              edit: _edit,
              decoratePane: _decoratePane,
            );
            return Column(
              children: [
                Expanded(
                  // The preview is for looking at: no field in it takes
                  // the keyboard.
                  child: ExcludeFocus(
                    child: LayoutScope(
                      config: _draft,
                      buttons: mainLayoutButtons,
                      editing: editing,
                      child: const MainView(),
                    ),
                  ),
                ),
                _Tray(
                  draft: _draft,
                  rules: _rules,
                  buttons: mainLayoutButtons,
                  edit: _edit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _decoratePane(
    BuildContext context,
    PaneLayout pane,
    int index,
    Widget child,
  ) {
    return _EditablePane(
      pane: pane,
      index: index,
      contentIndex: _draft.panes.indexWhere(
        (p) => _rules.panes[p.id]?.fill ?? false,
      ),
      rules: _rules,
      edit: _edit,
      child: child,
    );
  }
}

class _EditorMessage extends StatelessWidget {
  const _EditorMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

/// One pane in the editor: the live pane made inert (its slots excepted),
/// outlined, with a handle to drag it by (and hide it, where allowed), a
/// drop zone for other panes, and — where it can be resized — a grip on the
/// edge that faces the chat.
class _EditablePane extends StatelessWidget {
  const _EditablePane({
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resizable = rules.panes[pane.id]?.resizable ?? false;
    final label = mainPaneLabels[pane.id] ?? pane.id;
    final gripOnRight = index < contentIndex;

    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutEditBarrier(child: child),
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
        _PaneDropZone(paneId: pane.id, index: index, edit: edit),
        Center(
          child: _PaneHandle(
            paneId: pane.id,
            label: label,
            compact: (pane.width ?? double.infinity) < 150,
            onHide: rules.canHidePane(pane.id)
                ? () => edit((c) => c.setPaneVisible(pane.id, false))
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
              edit: edit,
            ),
          ),
      ],
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
class _Tray extends StatelessWidget {
  const _Tray({
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
                      'Drag a button here to remove it; drag one from here '
                      'into a toolbar to add it.');
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
