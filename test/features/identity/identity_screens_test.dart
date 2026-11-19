// The screens a person meets before and around signing in: that each one
// builds, says what it is for, and offers the way out it promises. What they
// do is covered where it can be checked for real — the integration tests.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/models/server_profile.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/storage/app_prefs.dart';
import 'package:raindrop_client/core/theme/theme_controller.dart';
import 'package:raindrop_client/features/identity/screens/welcome_screen.dart';
import 'package:raindrop_client/features/identity/widgets/lock_gate.dart';
import 'package:raindrop_client/features/identity/widgets/server_address_fields.dart';
import 'package:raindrop_client/features/servers/controllers/session_controller.dart';
import 'package:raindrop_client/features/servers/widgets/server_unreachable_pane.dart';
import 'package:raindrop_client/features/servers/widgets/sign_in_pane.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _server = ServerProfile(
  id: '0f8fad5b-d9cb-469f-a165-70867728950e',
  host: 'home.example',
  port: 5001,
  displayName: 'Home',
);

Future<Widget> _app(Widget child, {List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  final prefs = AppPrefs(await SharedPreferences.getInstance());
  return ProviderScope(
    overrides: [appPrefsProvider.overrideWithValue(prefs), ...overrides],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('a fresh install is offered three ways to an identity', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(const WelcomeScreen()));

    expect(find.text("I'm new to Raindrop"), findsOneWidget);
    expect(find.text('I use Raindrop on another device'), findsOneWidget);
    expect(find.text('Use my recovery words'), findsOneWidget);
    expect(find.textContaining('no passwords'), findsOneWidget);
  });

  testWidgets('a device the system cannot unlock must choose a PIN first', (
    tester,
  ) async {
    // No local_auth plugin answers in a test, which is exactly a device with
    // no biometrics or system lock to use.
    await tester.pumpWidget(
      await _app(const LockGate(child: Text('the app'))),
    );
    // Asking the platform how it unlocks is a real platform call.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.text('the app'), findsNothing);
    expect(find.text('Choose a PIN for Raindrop'), findsOneWidget);

    // Too short, then mismatched: neither gets past the gate.
    await tester.enterText(find.byType(TextField).first, '123');
    await tester.enterText(find.byType(TextField).last, '123');
    await tester.tap(find.text('Set PIN'));
    await tester.pump();
    expect(find.text('Use at least 6 characters.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'correct horse');
    await tester.enterText(find.byType(TextField).last, 'correct house');
    await tester.tap(find.text('Set PIN'));
    await tester.pump();
    expect(find.text('The two do not match.'), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });

  group('a server that would not sign in asks for the one thing missing', () {
    Future<void> show(WidgetTester tester, String code) async {
      await tester.pumpWidget(
        await _app(
          const SignInPane(profile: _server),
          overrides: [
            signInFailureProvider(
              _server.id,
            ).overrideWith((ref) => ApiException(401, code, 'refused')),
          ],
        ),
      );
    }

    testWidgets('an authenticator code', (tester) async {
      await show(tester, 'authenticator_required');
      expect(find.text('Authenticator code'), findsOneWidget);
      expect(find.text('Remove from this device'), findsOneWidget);
    });

    testWidgets('a way to wait, when the codes are lost too', (tester) async {
      await show(tester, 'authenticator_required');
      expect(find.text('I lost my authenticator and codes'), findsOneWidget);

      await tester.tap(find.text('I lost my authenticator and codes'));
      await tester.pumpAndSettle();
      // Said plainly before anything starts: a wait, and the other devices
      // can stop it.
      expect(find.text('Lost your authenticator?'), findsOneWidget);
      expect(find.textContaining('can stop it'), findsOneWidget);
    });

    testWidgets('the end of a wait already running', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPrefs(await SharedPreferences.getInstance());
      await prefs.setRecoveryWait(_server.id, DateTime.utc(2030, 1, 2, 12));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPrefsProvider.overrideWithValue(prefs),
            signInFailureProvider(_server.id).overrideWith(
              (ref) => const ApiException(409, 'recovery_pending', 'wait'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SignInPane(profile: _server)),
          ),
        ),
      );

      expect(find.textContaining('January 2, 2030'), findsOneWidget);
      expect(find.text('Check now'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // A code found in the meantime is still welcome.
      await tester.tap(find.text('Enter a code instead'));
      await tester.pump();
      expect(find.text('Authenticator code'), findsOneWidget);
    });

    testWidgets('a code, when a device stopped the wait', (tester) async {
      await show(tester, 'recovery_cancelled');
      expect(find.text('Authenticator code'), findsOneWidget);
      expect(find.textContaining('stopped this device'), findsOneWidget);
      expect(find.text('I lost my authenticator and codes'), findsNothing);
    });

    testWidgets('nothing but removing it, when another identity has it', (
      tester,
    ) async {
      await show(tester, 'identity_mismatch');
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('belongs to a different identity'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      // One way out, not two.
      expect(find.text('Remove from this device'), findsOneWidget);
    });

    testWidgets('a username, when the account is gone', (tester) async {
      await show(tester, 'invalid_username');
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Join again'), findsOneWidget);
    });

    testWidgets('a go-ahead, when this device was removed', (tester) async {
      await show(tester, 'invalid_credentials');
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Set this device up again'), findsOneWidget);
    });
  });

  testWidgets('a server address is typed as an address, not as prose', (
    tester,
  ) async {
    final host = TextEditingController();
    final port = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ServerAddressFields(host: host, port: port)),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.keyboardType, TextInputType.url);
    host.dispose();
    port.dispose();
  });

  testWidgets('an unreachable server can still be removed from this device', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _app(
        ServerUnreachablePane(
          profile: _server,
          error: ApiException.network('nothing answered'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Can't reach Home"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Remove from this device'));
    await tester.pumpAndSettle();
    // The confirmation says what removing does and does not do.
    expect(find.textContaining('Your account stays on the server'), findsOneWidget);
  });
}
