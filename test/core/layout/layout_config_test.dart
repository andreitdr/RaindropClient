import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/layout/layout_config.dart';
import 'package:raindrop_client/core/layout/layout_store.dart';
import 'package:raindrop_client/features/home/layout/main_layout.dart';
import 'package:raindrop_client/features/home/layout/main_layout_ids.dart';

const rules = mainLayoutRules;

LayoutConfig normalized([LayoutConfig config = mainDefaultLayout]) =>
    config.normalize(rules);

List<String> order(LayoutConfig config) => [
  for (final p in config.panes) p.id,
];

void main() {
  group('defaults', () {
    test('are the layout the main view had before it could change', () {
      final layout = normalized();
      expect(order(layout), [
        MainPanes.servers,
        MainPanes.channels,
        MainPanes.content,
        MainPanes.members,
      ]);
      expect(layout.pane(MainPanes.servers)!.width, 76);
      expect(layout.pane(MainPanes.channels)!.width, 240);
      expect(layout.pane(MainPanes.content)!.width, isNull);
      expect(layout.pane(MainPanes.members)!.width, 240);
      expect(layout.slot(MainSlots.railFooter), [
        MainButtons.addServer,
        MainButtons.settings,
      ]);
      expect(layout.slot(MainSlots.userPanel), [
        MainButtons.mute,
        MainButtons.deafen,
        MainButtons.camera,
        MainButtons.settings,
      ]);
      expect(layout.slot(MainSlots.topBar), [MainButtons.members]);
    });

    test('are already normal', () {
      expect(normalized(), mainDefaultLayout);
    });
  });

  group('JSON', () {
    test('round-trips', () {
      final layout = normalized()
          .movePane(MainPanes.members, 0)
          .resizePane(MainPanes.channels, 300)
          .placeButton(
            MainButtons.settings,
            slotId: MainSlots.topBar,
            index: 0,
          );
      expect(LayoutConfig.decode(layout.encode()), layout);
    });

    test('an empty object reads as the defaults once normalized', () {
      expect(LayoutConfig.decode('{}').normalize(rules), normalized());
    });

    test('a wrong shape is a FormatException', () {
      expect(() => LayoutConfig.decode('[]'), throwsFormatException);
      expect(
        () => LayoutConfig.decode('{"panes": {}}'),
        throwsFormatException,
      );
      expect(
        () => LayoutConfig.decode('{"panes": [{"width": 3}]}'),
        throwsFormatException,
      );
      expect(
        () => LayoutConfig.decode('{"slots": {"rail.footer": "x"}}'),
        throwsFormatException,
      );
      expect(() => LayoutConfig.decode('not json'), throwsFormatException);
    });
  });

  group('normalize', () {
    test('keeps the first of a pane listed twice', () {
      final layout = LayoutConfig(
        panes: [
          const PaneLayout(id: MainPanes.members, width: 200),
          ...mainDefaultLayout.panes,
        ],
        slots: mainDefaultLayout.slots,
      ).normalize(rules);
      expect(order(layout), [
        MainPanes.members,
        MainPanes.servers,
        MainPanes.channels,
        MainPanes.content,
      ]);
      expect(layout.pane(MainPanes.members)!.width, 200);
    });

    test('puts a missing pane back beside its default neighbour', () {
      final layout = const LayoutConfig(
        panes: [
          PaneLayout(id: MainPanes.content),
          PaneLayout(id: MainPanes.servers, width: 76),
        ],
        slots: {},
      ).normalize(rules);
      expect(order(layout), [
        MainPanes.content,
        MainPanes.members,
        MainPanes.servers,
        MainPanes.channels,
      ]);
    });

    test('clamps widths, and resets the ones that cannot change', () {
      final layout = normalized()
          .resizePane(MainPanes.channels, 10)
          .resizePane(MainPanes.members, 9000)
          .resizePane(MainPanes.servers, 300)
          .resizePane(MainPanes.content, 500)
          .normalize(rules);
      expect(layout.pane(MainPanes.channels)!.width, 180);
      expect(layout.pane(MainPanes.members)!.width, 400);
      expect(layout.pane(MainPanes.servers)!.width, 76);
      expect(layout.pane(MainPanes.content)!.width, isNull);
    });

    test('a width that is not a number falls back to the default', () {
      final layout = normalized()
          .resizePane(MainPanes.channels, double.nan)
          .normalize(rules);
      expect(layout.pane(MainPanes.channels)!.width, 240);
    });

    test('required panes cannot be hidden; the member list can', () {
      final layout = normalized()
          .setPaneVisible(MainPanes.channels, false)
          .setPaneVisible(MainPanes.members, false)
          .normalize(rules);
      expect(layout.pane(MainPanes.channels)!.visible, isTrue);
      expect(layout.pane(MainPanes.members)!.visible, isFalse);
    });

    test('Settings goes back to its default slot when it is in none', () {
      final layout = normalized()
          // Settings is the last of the user panel's four.
          .removeButton(MainSlots.userPanel, 3)
          .removeButton(MainSlots.railFooter, 1)
          .normalize(rules);
      expect(layout.slot(MainSlots.railFooter), [
        MainButtons.addServer,
        MainButtons.settings,
      ]);
      expect(layout.slot(MainSlots.userPanel), [
        MainButtons.mute,
        MainButtons.deafen,
        MainButtons.camera,
      ]);
    });

    test('an emptied slot stays empty; a missing one gets the defaults', () {
      final layout = const LayoutConfig(
        panes: [],
        slots: {MainSlots.topBar: []},
      ).normalize(rules);
      expect(layout.slot(MainSlots.topBar), isEmpty);
      expect(layout.slot(MainSlots.railFooter), [
        MainButtons.addServer,
        MainButtons.settings,
      ]);
    });

    test('a slot never lists a button twice', () {
      final layout = const LayoutConfig(
        panes: [],
        slots: {
          MainSlots.topBar: [MainButtons.mute, MainButtons.mute],
        },
      ).normalize(rules);
      expect(layout.slot(MainSlots.topBar), [MainButtons.mute]);
    });

    test('keeps ids this build does not know', () {
      final layout = LayoutConfig(
        panes: [
          ...mainDefaultLayout.panes,
          const PaneLayout(id: 'plugin.notes', width: 123),
        ],
        slots: {
          ...mainDefaultLayout.slots,
          MainSlots.topBar: [MainButtons.members, 'plugin.button'],
          'plugin.slot': ['x'],
        },
      ).normalize(rules);
      expect(layout.pane('plugin.notes')!.width, 123);
      expect(layout.slot(MainSlots.topBar), contains('plugin.button'));
      expect(layout.slot('plugin.slot'), ['x']);
    });
  });

  group('edits', () {
    test('movePane lands before the pane at the index', () {
      final base = normalized();
      expect(order(base.movePane(MainPanes.members, 0)), [
        MainPanes.members,
        MainPanes.servers,
        MainPanes.channels,
        MainPanes.content,
      ]);
      expect(order(base.movePane(MainPanes.servers, 4)), [
        MainPanes.channels,
        MainPanes.content,
        MainPanes.members,
        MainPanes.servers,
      ]);
      expect(order(base.movePane(MainPanes.servers, 2)), [
        MainPanes.channels,
        MainPanes.servers,
        MainPanes.content,
        MainPanes.members,
      ]);
    });

    test('placeButton moves between slots', () {
      final layout = normalized().placeButton(
        MainButtons.addServer,
        slotId: MainSlots.topBar,
        index: 0,
        fromSlot: MainSlots.railFooter,
        fromIndex: 0,
      );
      expect(layout.slot(MainSlots.railFooter), [MainButtons.settings]);
      expect(layout.slot(MainSlots.topBar), [
        MainButtons.addServer,
        MainButtons.members,
      ]);
    });

    test('placeButton reorders within a slot', () {
      final layout = normalized().placeButton(
        MainButtons.mute,
        slotId: MainSlots.userPanel,
        index: 4,
        fromSlot: MainSlots.userPanel,
        fromIndex: 0,
      );
      expect(layout.slot(MainSlots.userPanel), [
        MainButtons.deafen,
        MainButtons.camera,
        MainButtons.settings,
        MainButtons.mute,
      ]);
    });

    test('placeButton from the palette copies, without doubling up', () {
      final copied = normalized().placeButton(
        MainButtons.settings,
        slotId: MainSlots.topBar,
        index: 1,
      );
      expect(copied.slot(MainSlots.topBar), [
        MainButtons.members,
        MainButtons.settings,
      ]);
      expect(copied.buttonCount(MainButtons.settings), 3);

      final again = copied.placeButton(
        MainButtons.settings,
        slotId: MainSlots.topBar,
        index: 0,
      );
      expect(again.slot(MainSlots.topBar), [
        MainButtons.settings,
        MainButtons.members,
      ]);
    });

    test('the last Settings button cannot be removed', () {
      final one = normalized().removeButton(MainSlots.userPanel, 3);
      expect(rules.canRemoveButton(one, MainSlots.railFooter, 1), isFalse);
      expect(rules.canRemoveButton(one, MainSlots.railFooter, 0), isTrue);
      expect(
        rules.canRemoveButton(normalized(), MainSlots.railFooter, 1),
        isTrue,
      );
    });
  });

  group('LayoutStore', () {
    late Directory dir;
    late LayoutStore store;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('raindrop_layout_test');
      store = LayoutStore(dir);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('no file is no layout', () async {
      expect(await store.load(), isNull);
    });

    test('saves and loads', () async {
      final layout = normalized().movePane(MainPanes.members, 0);
      await store.save(layout);
      expect(await store.load(), layout);
      expect(File('${dir.path}/layout.json.tmp').existsSync(), isFalse);
    });

    test('a corrupt file is moved aside, not loaded', () async {
      store.file.writeAsStringSync('{ nope');
      expect(await store.load(), isNull);
      expect(store.file.existsSync(), isFalse);
      expect(File('${dir.path}/layout.json.bad').existsSync(), isTrue);
    });

    test('delete removes the file', () async {
      await store.save(normalized());
      await store.delete();
      expect(store.file.existsSync(), isFalse);
    });

    test('exports and imports', () async {
      final layout = normalized().resizePane(MainPanes.members, 321);
      final path = '${dir.path}/exported.json';
      await LayoutStore.writeTo(path, layout);
      expect(await LayoutStore.readFrom(path), layout);
    });
  });
}
