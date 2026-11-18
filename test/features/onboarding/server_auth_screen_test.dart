// Backing out of "Join this server" closes the flow it was handed, and a flow
// that got as far as making this device's keys deletes them. That runs from
// the screen's `dispose`, when the screen's own `ref` can no longer be used,
// so the flow is closed through the app's container instead.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/crypto/crypto_store.dart';
import 'package:raindrop_client/core/network/users_api.dart';
import 'package:raindrop_client/core/storage/app_prefs.dart';
import 'package:raindrop_client/core/storage/identity_store.dart';
import 'package:raindrop_client/core/theme/theme_controller.dart';
import 'package:raindrop_client/features/onboarding/controllers/connect_server_flow.dart';
import 'package:raindrop_client/features/onboarding/screens/server_auth_screen.dart';
import 'package:raindrop_client/features/security/controllers/device_setup_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what would be deleted instead of touching the disk.
class _RecordingStores extends CryptoStores {
  _RecordingStores();

  final deleted = <String>[];

  @override
  Future<void> delete(String serverId) async => deleted.add(serverId);
}

void main() {
  testWidgets('leaving the join screen deletes the keys it made, without an '
      'error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = AppPrefs(await SharedPreferences.getInstance());

    const guid = '0f8fad5b-d9cb-469f-a165-70867728950e';
    final stores = _RecordingStores();
    final flow = ConnectServerFlow(
      host: 'home.example',
      port: 5001,
      identity: ClientIdentity(
        root: Uint8List(32),
        recoverySeed: Uint8List(32),
      ),
      stores: stores,
    )..debugKeysMadeFor(guid);
    // A new account, so the screen waits for a username rather than signing
    // in by itself as it opens — as when the name picked was taken.
    final handoff = (
      flow: flow,
      status: const UserStateResult(userId: guid, state: 'unregistered'),
      displayName: 'Home',
    );

    final showing = ValueNotifier(true);
    addTearDown(showing.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPrefsProvider.overrideWithValue(prefs),
          // No Rust core in a unit test: the engine never opened, which the
          // flow already allows for.
          cryptoEngineProvider.overrideWith(
            (ref, serverId) => throw StateError('no engine here'),
          ),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showing,
            builder: (context, show, _) =>
                show ? ServerAuthScreen(handoff: handoff) : const Text('back'),
          ),
        ),
      ),
    );
    expect(find.text('Join this server'), findsOneWidget);

    // The person backs out; the app, and its container, carry on.
    showing.value = false;
    await tester.pumpAndSettle();

    expect(find.text('back'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(stores.deleted, [guid]);
  });
}
