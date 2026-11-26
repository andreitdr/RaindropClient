// The confirmation a changed identity key waits for: that it shows both safety
// numbers and what the server says, accepts only when the person says so, and
// that the banner and the held message point at it. The accepting itself runs
// through the real ChannelGroups over a fake engine; the Rust core is not
// involved.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/crypto_engine.dart';
import 'package:raindrop_client/core/network/e2ee_api.dart';
import 'package:raindrop_client/features/security/controllers/channel_groups.dart';
import 'package:raindrop_client/features/security/controllers/identity_changes.dart';
import 'package:raindrop_client/features/security/widgets/identity_change_banner.dart';
import 'package:raindrop_client/features/security/widgets/identity_change_dialog.dart';
import 'package:raindrop_client/features/servers/controllers/user_lookup.dart';

const _server = 'server-1';
const _channel = '6f1c2d3e-4a5b-4c6d-8e7f-001122334455';
const _otherChannel = '11111111-2222-4333-8444-555555555555';

final _oldKey = Uint8List.fromList(List.filled(32, 0xA1));
final _newKey = Uint8List.fromList(List.filled(32, 0xB2));
final _otherKey = Uint8List.fromList(List.filled(32, 0xC3));

final _pinnedNumber =
    '12345 67890 12345 67890 12345 67890 12345 67890 12345 67890 12345 67890'
        .replaceAll(' ', '');
final _presentedNumber =
    '98765 43210 98765 43210 98765 43210 98765 43210 98765 43210 98765 43210'
        .replaceAll(' ', '');

final _change = PendingIdentityChange(
  userId: 'bob',
  pinnedKey: _oldKey,
  presentedKey: _newKey,
  heldMessages: 2,
  heldGroupIds: [groupIdForChannel(_channel)],
);

class _Engine implements CryptoEngine {
  _Engine(this.pending);

  final List<PendingIdentityChange> pending;
  final accepted = <({String userId, Uint8List key})>[];

  @override
  Future<List<PendingIdentityChange>> pendingIdentityChanges() async =>
      List.of(pending);

  @override
  Future<void> acceptChangedIdentity(
    String userId,
    Uint8List identityKey,
  ) async {
    accepted.add((userId: userId, key: identityKey));
    pending.removeWhere(
      (c) => c.userId == userId && listEquals(c.presentedKey, identityKey),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Api implements E2eeApi {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

IdentityEvidence _evidence({Uint8List? registered, bool failed = false}) =>
    IdentityEvidence(
      pinnedSafetyNumber: _pinnedNumber,
      presentedSafetyNumber: _presentedNumber,
      registeredKey: registered,
      registeredLookupFailed: failed,
    );

class _Harness {
  _Harness({
    FutureOr<IdentityEvidence>? evidence,
    List<PendingIdentityChange>? pending,
  }) : engine = _Engine(pending ?? [_change]),
       evidence = evidence ?? _evidence(registered: _newKey);

  final _Engine engine;
  final FutureOr<IdentityEvidence> evidence;

  Widget app(Widget Function(BuildContext) home) => ProviderScope(
    overrides: [
      channelGroupsProvider.overrideWith(
        (ref, serverId) async => ChannelGroups(
          engine: engine,
          api: _Api(),
          token: 'token',
          self: const DeviceRef(userId: 'alice', deviceId: 'a1'),
        ),
      ),
      identityEvidenceProvider.overrideWith((ref, arg) async => evidence),
      // Names come from the server; the fallback (the id's first part) will do.
      userLookupProvider.overrideWith((ref, who) async => null),
    ],
    child: MaterialApp(
      home: Scaffold(body: Builder(builder: home)),
    ),
  );
}

Widget _reviewButton(BuildContext context, {void Function(bool)? onDone}) =>
    Center(
      child: TextButton(
        onPressed: () async {
          final accepted = await reviewIdentityChange(
            context,
            serverId: _server,
            change: _change,
            userName: 'Bob',
          );
          onDone?.call(accepted);
        },
        child: const Text('open'),
      ),
    );

void main() {
  test('a safety number reads in groups of five, four to a line', () {
    expect(
      formatSafetyNumber(_pinnedNumber),
      '12345 67890 12345 67890\n12345 67890 12345 67890\n12345 67890 12345 67890',
    );
  });

  testWidgets('the dialog shows both safety numbers, the new key and what '
      'accepting does', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app((c) => _reviewButton(c)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text("Bob's security key changed"), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('pinned-safety-number'))).data,
      formatSafetyNumber(_pinnedNumber),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('presented-safety-number')))
          .data,
      formatSafetyNumber(_presentedNumber),
    );
    // The new key's fingerprint is the "Your identity" line the other person
    // reads from their own settings.
    expect(
      find.text('Key B2B2 B2B2 B2B2 B2B2 B2B2 B2B2 B2B2 B2B2'),
      findsOneWidget,
    );
    expect(
      find.text('Key A1A1 A1A1 A1A1 A1A1 A1A1 A1A1 A1A1 A1A1'),
      findsOneWidget,
    );
    // The server lists the same key: said, but not reassuring.
    expect(find.textContaining('lists this same key'), findsOneWidget);
    // Plainly what each answer does.
    expect(
      tester
          .widget<Text>(find.byKey(const Key('identity-change-effects')))
          .data,
      allOf(
        contains('Accepting trusts this key'),
        contains('2 messages'),
        contains('Not now changes nothing'),
      ),
    );
    expect(find.text('Accept new key'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    // Looking is not deciding.
    expect(harness.engine.accepted, isEmpty);
  });

  testWidgets('"Accept new key" accepts exactly the presented key', (
    tester,
  ) async {
    final harness = _Harness();
    bool? result;
    await tester.pumpWidget(
      harness.app((c) => _reviewButton(c, onDone: (r) => result = r)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept new key'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(harness.engine.accepted, hasLength(1));
    expect(harness.engine.accepted.single.userId, 'bob');
    expect(harness.engine.accepted.single.key, _newKey);
    expect(harness.engine.pending, isEmpty);
    expect(find.textContaining("You now trust Bob's new key"), findsOneWidget);
  });

  testWidgets('"Not now" accepts nothing and the change stays pending', (
    tester,
  ) async {
    final harness = _Harness();
    bool? result;
    await tester.pumpWidget(
      harness.app((c) => _reviewButton(c, onDone: (r) => result = r)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(harness.engine.accepted, isEmpty);
    expect(harness.engine.pending, [_change]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('dismissing the dialog is not accepting either', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app((c) => _reviewButton(c)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(4, 4)); // The barrier.
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(harness.engine.accepted, isEmpty);
  });

  testWidgets('a key the server disagrees about is flagged', (tester) async {
    final harness = _Harness(evidence: _evidence(registered: _otherKey));
    await tester.pumpWidget(harness.app((c) => _reviewButton(c)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('lists a different key'), findsOneWidget);
    expect(find.textContaining('C3C3 C3C3'), findsOneWidget);
    expect(find.textContaining('lists this same key'), findsNothing);
    expect(harness.engine.accepted, isEmpty);
  });

  testWidgets('a server that cannot be asked is said so', (tester) async {
    final harness = _Harness(evidence: _evidence(failed: true));
    await tester.pumpWidget(harness.app((c) => _reviewButton(c)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not be asked'), findsOneWidget);
  });

  testWidgets('accepting waits until the safety numbers are on screen', (
    tester,
  ) async {
    final evidence = Completer<IdentityEvidence>();
    final harness = _Harness(evidence: evidence.future);
    await tester.pumpWidget(harness.app((c) => _reviewButton(c)));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();

    final accept = find.widgetWithText(FilledButton, 'Accept new key');
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    await tester.tap(accept, warnIfMissed: false);
    await tester.pump();
    expect(harness.engine.accepted, isEmpty);

    evidence.complete(_evidence(registered: _newKey));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
  });

  testWidgets(
    'the banner shows in a channel the change touches, and only there',
    (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(
        harness.app(
          (_) => const Column(
            children: [
              IdentityChangeBanner(serverId: _server, channelId: _channel),
              IdentityChangeBanner(serverId: _server, channelId: _otherChannel),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // One banner, for the channel with the held messages; Review is on it.
      expect(find.byKey(const Key('identity-banner-bob')), findsOneWidget);
      expect(
        find.textContaining(
          "bob's security key changed. Their messages are hidden",
        ),
        findsOneWidget,
      );
      expect(find.text('Review'), findsOneWidget);
      expect(harness.engine.accepted, isEmpty);
    },
  );

  testWidgets('the banner says when this device is out of the channel', (
    tester,
  ) async {
    final harness = _Harness(
      pending: [
        PendingIdentityChange(
          userId: 'bob',
          pinnedKey: _oldKey,
          presentedKey: _newKey,
          leftGroupIds: [groupIdForChannel(_channel)],
        ),
      ],
    );
    await tester.pumpWidget(
      harness.app(
        (_) =>
            const IdentityChangeBanner(serverId: _server, channelId: _channel),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining("out of the channel's encryption"),
      findsOneWidget,
    );
  });

  testWidgets('the banner goes once the change is accepted', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.app(
        (_) =>
            const IdentityChangeBanner(serverId: _server, channelId: _channel),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept new key'));
    await tester.pumpAndSettle();

    expect(harness.engine.accepted.single.key, _newKey);
    expect(find.byKey(const Key('identity-banner-bob')), findsNothing);
  });
}
