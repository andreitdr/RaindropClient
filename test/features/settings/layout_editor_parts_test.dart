import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/layout/layout_config.dart';
import 'package:raindrop_client/core/layout/layout_row.dart';
import 'package:raindrop_client/core/layout/layout_scope.dart';
import 'package:raindrop_client/core/theme/app_colors.dart';
import 'package:raindrop_client/core/layout/layout_slot.dart';
import 'package:raindrop_client/features/home/layout/main_layout.dart';
import 'package:raindrop_client/features/home/layout/main_layout_ids.dart';
import 'package:raindrop_client/features/settings/widgets/layout_editor_parts.dart';

/// Stand-ins for the real buttons, which need a signed-in app.
final buttons = {
  for (final spec in mainLayoutButtons.values)
    spec.id: LayoutButtonSpec(
      id: spec.id,
      label: spec.label,
      icon: spec.icon,
      build: (context, style) => TextButton(
        onPressed: () {},
        child: Text('live:${spec.id}'),
      ),
    ),
};

/// A pane like the real ones: content that fills it, with its slot where the
/// real pane has it.
Widget paneBody(String id) => Column(
  children: [
    Expanded(child: Container(color: const Color(0xFF202020))),
    if (id == MainPanes.servers)
      const LayoutSlot(
        MainSlots.railFooter,
        style: SlotStyle.rail,
        axis: Axis.vertical,
      ),
    if (id == MainPanes.channels) const LayoutSlot(MainSlots.userPanel),
    if (id == MainPanes.content)
      const Align(
        alignment: Alignment.topRight,
        child: LayoutSlot(MainSlots.topBar),
      ),
  ],
);

void main() {
  late LayoutConfig config;

  Future<void> pump(
    WidgetTester tester, {
    LayoutConfig? start,
    Size size = const Size(1400, 900),
  }) async {
    config = (start ?? mainDefaultLayout).normalize(mainLayoutRules);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppSurfaces.dark]),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              void edit(LayoutConfig Function(LayoutConfig) update) =>
                  setState(
                    () => config = update(config).normalize(mainLayoutRules),
                  );
              return LayoutScope(
                config: config,
                buttons: buttons,
                editing: LayoutEditing(
                  rules: mainLayoutRules,
                  edit: edit,
                  decoratePane: (context, pane, index, child) =>
                      LayoutPaneEditor(
                        pane: pane,
                        index: index,
                        contentIndex: config.panes.indexWhere(
                          (p) => mainLayoutRules.panes[p.id]?.fill ?? false,
                        ),
                        rules: mainLayoutRules,
                        edit: edit,
                        child: child,
                      ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutRow(
                        paneBuilder: (context, pane) => paneBody(pane.id),
                      ),
                    ),
                    LayoutEditorTray(
                      draft: config,
                      rules: mainLayoutRules,
                      buttons: buttons,
                      edit: edit,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The tray's palette chip for [label] (the tray shows labels; slots do
  /// not).
  Finder palette(String label) => find.descendant(
    of: find.byType(LayoutEditorTray),
    matching: find.widgetWithText(LayoutButtonChip, label),
  );

  Future<void> dragTo(
    WidgetTester tester,
    Finder from,
    Offset target,
  ) async {
    final gesture = await tester.startGesture(tester.getCenter(from));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(from) + const Offset(30, -30));
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a button drags from the tray onto a chip already in a slot', (
    tester,
  ) async {
    await pump(tester);
    // Onto the top bar's Members chip: it lands before it.
    final members = find.descendant(
      of: find.byType(LayoutSlot),
      matching: find.byType(LayoutButtonChip),
    );
    await dragTo(
      tester,
      palette('Add a server'),
      tester.getCenter(members.last),
    );
    expect(config.slot(MainSlots.topBar), [
      MainButtons.addServer,
      MainButtons.members,
    ]);
  });

  testWidgets('a button drags from the tray into an emptied slot', (
    tester,
  ) async {
    await pump(
      tester,
      start: mainDefaultLayout.copyWith(
        slots: {...mainDefaultLayout.slots, MainSlots.topBar: const []},
      ),
    );
    final slot = find.byWidgetPredicate(
      (w) => w is LayoutSlot && w.slotId == MainSlots.topBar,
    );
    expect(slot, findsOneWidget);
    await dragTo(tester, palette('Show members'), tester.getCenter(slot));
    expect(config.slot(MainSlots.topBar), [MainButtons.members]);
  });

  testWidgets('a button dropped anywhere on a pane joins its toolbar', (
    tester,
  ) async {
    await pump(tester);
    // The middle of the channel list, nowhere near its user panel.
    final pane = find.byType(LayoutPaneEditor).at(1);
    await dragTo(tester, palette('Show members'), tester.getCenter(pane));
    expect(config.slot(MainSlots.userPanel), [
      MainButtons.mute,
      MainButtons.deafen,
      MainButtons.settings,
      MainButtons.members,
    ]);
  });

  testWidgets('a button dropped on a chip still lands at that chip', (
    tester,
  ) async {
    await pump(tester);
    // The user panel's first chip, inside a pane that now takes drops too:
    // the slot is the finer target and wins.
    final firstChip = find
        .descendant(
          of: find.byWidgetPredicate(
            (w) => w is LayoutSlot && w.slotId == MainSlots.userPanel,
          ),
          matching: find.byType(LayoutButtonChip),
        )
        .first;
    await dragTo(
      tester,
      palette('Show members'),
      tester.getCenter(firstChip),
    );
    expect(config.slot(MainSlots.userPanel), [
      MainButtons.members,
      MainButtons.mute,
      MainButtons.deafen,
      MainButtons.settings,
    ]);
  });

  testWidgets('the member list takes no buttons: it has no toolbar', (
    tester,
  ) async {
    await pump(tester);
    final members = find.byType(LayoutPaneEditor).last;
    await dragTo(tester, palette('Show members'), tester.getCenter(members));
    expect(config.slot(MainSlots.topBar), [MainButtons.members]);
    expect(config.slots.values.expand((s) => s), isNot(contains('members')));
  });

  testWidgets('a pane drags onto the middle of another, over its handle', (
    tester,
  ) async {
    await pump(tester);
    final handles = find.byType(LayoutPaneEditor);
    final members = tester.getCenter(handles.last);
    // Onto the left half of the rail: the member list lands before it.
    final rail = tester.getTopLeft(handles.first) + const Offset(12, 300);
    final gesture = await tester.startGesture(members);
    await tester.pump();
    await gesture.moveTo(members - const Offset(40, 0));
    await tester.pump();
    await gesture.moveTo(rail);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect([for (final p in config.panes) p.id], [
      MainPanes.members,
      MainPanes.servers,
      MainPanes.channels,
      MainPanes.content,
    ]);
  });

  testWidgets('a hidden pane comes back from the tray', (tester) async {
    await pump(
      tester,
      start: mainDefaultLayout.setPaneVisible(MainPanes.members, false),
    );
    await tester.tap(find.widgetWithText(ActionChip, 'Show Members'));
    await tester.pump();
    expect(config.pane(MainPanes.members)!.visible, isTrue);
  });
}
