import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_definition.dart';

/// Create or edit a custom theme. Editing a built-in theme (`light`/`dark`)
/// forks it into a new custom one with a generated id — [starting] carries
/// the colors to pre-fill, [editing] is only set when this is really an
/// in-place edit of an existing custom theme.
class ThemeEditorScreen extends ConsumerStatefulWidget {
  const ThemeEditorScreen({super.key, required this.starting, this.editing});

  final AppThemeDefinition starting;
  final AppThemeDefinition? editing;

  @override
  ConsumerState<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends ConsumerState<ThemeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late Brightness _brightness;
  late Color _seedColor;
  late Color _rail;
  late Color _sidebar;
  late Color _chat;
  late Color _raised;
  late Color _onlineIndicator;

  @override
  void initState() {
    super.initState();
    final base = widget.starting;
    _nameController = TextEditingController(
      text: widget.editing?.name ?? '${base.name} copy',
    );
    _brightness = base.brightness;
    _seedColor = base.seedColor;
    _rail = base.surfaces.rail;
    _sidebar = base.surfaces.sidebar;
    _chat = base.surfaces.chat;
    _raised = base.surfaces.raised;
    _onlineIndicator = base.surfaces.onlineIndicator;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final theme = AppThemeDefinition(
      id: widget.editing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      brightness: _brightness,
      seedColor: _seedColor,
      surfaces: AppSurfaces(
        rail: _rail,
        sidebar: _sidebar,
        chat: _chat,
        raised: _raised,
        onlineIndicator: _onlineIndicator,
      ),
    );
    ref.read(themeCatalogProvider.notifier).addOrUpdate(theme);
    ref.read(activeThemeIdProvider.notifier).select(theme.id);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = AppThemeDefinition(
      id: 'preview',
      name: _nameController.text,
      brightness: _brightness,
      seedColor: _seedColor,
      surfaces: AppSurfaces(
        rail: _rail,
        sidebar: _sidebar,
        chat: _chat,
        raised: _raised,
        onlineIndicator: _onlineIndicator,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing == null ? 'New theme' : 'Edit theme'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<Brightness>(
            segments: const [
              ButtonSegment(
                value: Brightness.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: Brightness.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {_brightness},
            onSelectionChanged: (s) => setState(() => _brightness = s.first),
          ),
          const SizedBox(height: 20),
          Text('Colors', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _ColorField(
            label: 'Accent',
            value: _seedColor,
            onChanged: (c) => setState(() => _seedColor = c),
          ),
          _ColorField(
            label: 'Rail',
            value: _rail,
            onChanged: (c) => setState(() => _rail = c),
          ),
          _ColorField(
            label: 'Sidebar',
            value: _sidebar,
            onChanged: (c) => setState(() => _sidebar = c),
          ),
          _ColorField(
            label: 'Chat background',
            value: _chat,
            onChanged: (c) => setState(() => _chat = c),
          ),
          _ColorField(
            label: 'Raised surfaces',
            value: _raised,
            onChanged: (c) => setState(() => _raised = c),
          ),
          _ColorField(
            label: 'Online indicator',
            value: _onlineIndicator,
            onChanged: (c) => setState(() => _onlineIndicator = c),
          ),
          const SizedBox(height: 20),
          Text('Preview', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _ThemePreview(theme: preview),
        ],
      ),
    );
  }
}

class _ColorField extends StatefulWidget {
  const _ColorField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<_ColorField> {
  late final TextEditingController _controller;

  static String _hex(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _hex(widget.value));
  }

  @override
  void didUpdateWidget(covariant _ColorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _hex(widget.value);
    if (_controller.text.toUpperCase() != current) _controller.text = current;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final hex = raw.replaceFirst('#', '');
    if (hex.length != 6 || int.tryParse(hex, radix: 16) == null) return;
    widget.onChanged(Color(int.parse('FF$hex', radix: 16)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.value,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.label)),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F#]')),
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: const InputDecoration(prefixText: '#', isDense: true),
              onSubmitted: _submit,
              onEditingComplete: () => _submit(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// A miniature, non-interactive stand-in for the server rail + sidebar so a
/// color change is visible immediately instead of only after saving.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final AppThemeDefinition theme;

  @override
  Widget build(BuildContext context) {
    final themeData = theme.toThemeData();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 120,
        child: Theme(
          data: themeData,
          child: Row(
            children: [
              Container(width: 48, color: theme.surfaces.rail),
              Container(width: 96, color: theme.surfaces.sidebar),
              Expanded(
                child: Container(
                  color: theme.surfaces.chat,
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surfaces.raised,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        color: themeData.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
