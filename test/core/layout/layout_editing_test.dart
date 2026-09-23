import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/layout/layout_config.dart';
import 'package:raindrop_client/core/layout/layout_edit_barrier.dart';
import 'package:raindrop_client/core/layout/layout_row.dart';
import 'package:raindrop_client/core/layout/layout_scope.dart';
import 'package:raindrop_client/core/layout/layout_slot.dart';
import 'package:raindrop_client/features/home/layout/main_layout.dart';
import 'package:raindrop_client/features/home/layout/main_layout_ids.dart';

// Plain buttons standing in for the real ones, which need a signed-in app.
final buttons = {
  for (final id in [
    MainButtons.addServer,
    MainButtons.settings,
    MainButtons.mute,
    MainButtons.deafen,
    MainButtons.members,
  ])
    id: LayoutButtonSpec(
      id: id,
      label: id,
      icon: Icons.circle,
      build: (context, style) => TextButton(
        key: ValueKey('live:$id'),
        onPressed: () {},
        child: Text(id),
      ),
    ),
};

/// The main view's panes, each a box with a button of its own, the rail and
/// the chat holding their slots.
Widget pane(BuildContext context, PaneLayout pane, void Function() onTap) =>
    Column(
      children: [
        TextButton(
          key: ValueKey('pane:${pane.id}'),
          onPressed: onTap,
          child: Text(pane.id),
        ),
        if (pane.id == MainPanes.servers)
          const LayoutSlot(MainSlots.railFooter, axis: Axis.vertical),
        if (pane.id == MainPanes.content)
          const LayoutSlot(MainSlots.topBar),
      ],
    );

void main() {
  Future<LayoutConfig Function()> pump(
    WidgetTester tester, {
    required bool editing,
    required void Function() onPaneTap,
  }) async {
    var config = mainDefaultLayout;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LayoutScope(
              config: config,
              buttons: buttons,
              editing: editing
                  ? LayoutEditing(
                      rules: mainLayoutRules,
                      edit: (update) => setState(
                        () => config = update(config).normalize(
                          mainLayoutRules,
                        ),
                      ),
                      decoratePane: (context, pane, index, child) =>
                          LayoutEditBarrier(child: child),
                    )
                  : null,
              child: LayoutRow(
                paneBuilder: (context, p) => pane(context, p, onPaneTap),
              ),
            ),
          ),
        ),
      ),
    );
    return () => config;
  }

  testWidgets('outside the editor, panes and slot buttons are live', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, editing: false, onPaneTap: () => taps++);
    await tester.tap(find.byKey(const ValueKey('pane:${MainPanes.channels}')));
    expect(taps, 1);
    expect(
      find.byKey(const ValueKey('live:${MainButtons.settings}')),
      findsOneWidget,
    );
    expect(find.byType(LayoutButtonChip), findsNothing);
  });

  testWidgets('in the editor, panes are inert but slots take drags', (
    tester,
  ) async {
    var taps = 0;
    final config = await pump(tester, editing: true, onPaneTap: () => taps++);

    await tester.tap(
      find.byKey(const ValueKey('pane:${MainPanes.channels}')),
      warnIfMissed: false,
    );
    expect(taps, 0);
    expect(find.byType(LayoutButtonChip), findsNWidgets(3));

    // "Add a server", the rail's first chip, onto the top bar's Members
    // chip: it lands before it.
    final chips = find.byType(LayoutButtonChip);
    final from = tester.getCenter(chips.first);
    final to = tester.getCenter(chips.last);
    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveTo(from + const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(config().slot(MainSlots.railFooter), [MainButtons.settings]);
    expect(config().slot(MainSlots.topBar), [
      MainButtons.addServer,
      MainButtons.members,
    ]);
  });
}
