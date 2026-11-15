import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/layout/layout_controller.dart';
import 'package:raindrop_client/core/layout/layout_scope.dart';
import 'package:raindrop_client/core/layout/layout_slot.dart';
import 'package:raindrop_client/features/home/layout/main_layout.dart';
import 'package:raindrop_client/features/home/layout/main_layout_ids.dart';

/// The real Members button, in the chat's top bar, under a scaffold that
/// either has the narrow layout's member drawer or does not.
Future<ProviderContainer> pump(
  WidgetTester tester, {
  required Set<String> collapsed,
  required bool withDrawer,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: LayoutScope(
          config: mainDefaultLayout,
          buttons: mainLayoutButtons,
          collapsedPanes: collapsed,
          child: Scaffold(
            endDrawer: withDrawer
                ? const Drawer(child: Text('member drawer'))
                : null,
            body: const Row(children: [LayoutSlot(MainSlots.topBar)]),
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('draws nothing while the member list is not collapsed', (
    tester,
  ) async {
    await pump(tester, collapsed: const {}, withDrawer: false);
    expect(find.byTooltip('Members'), findsNothing);
  });

  testWidgets('opens the member drawer under the narrow layout', (
    tester,
  ) async {
    final container = await pump(
      tester,
      collapsed: const {MainPanes.members},
      withDrawer: true,
    );
    expect(find.text('member drawer'), findsNothing);

    await tester.tap(find.byTooltip('Members'));
    await tester.pumpAndSettle();

    expect(find.text('member drawer'), findsOneWidget);
    // The wide layout's fold-out is left alone.
    expect(container.read(revealedPanesProvider), isEmpty);
  });

  testWidgets('folds the member pane in and out in the wide layout', (
    tester,
  ) async {
    final container = await pump(
      tester,
      collapsed: const {MainPanes.members},
      withDrawer: false,
    );

    await tester.tap(find.byTooltip('Members'));
    await tester.pump();
    expect(container.read(revealedPanesProvider), {MainPanes.members});

    await tester.tap(find.byTooltip('Members'));
    await tester.pump();
    expect(container.read(revealedPanesProvider), isEmpty);
  });
}
