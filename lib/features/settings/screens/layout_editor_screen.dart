import 'dart:io';

import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/layout_config.dart';
import '../../../core/layout/layout_controller.dart';
import '../../../core/layout/layout_scope.dart';
import '../../../core/layout/layout_store.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/widgets/adaptive.dart';
import '../../home/layout/main_layout.dart';
import '../../home/screens/home_shell.dart';
import '../widgets/layout_editor_parts.dart';
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
                LayoutEditorTray(
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
    return LayoutPaneEditor(
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
