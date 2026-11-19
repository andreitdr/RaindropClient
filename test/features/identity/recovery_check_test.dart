// Keeping the recovery words recoverable: confirming them by typing some back,
// the reminders to check them, and the emergency kit they can be printed on.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/storage/app_prefs.dart';
import 'package:raindrop_client/core/theme/theme_controller.dart';
import 'package:raindrop_client/features/identity/emergency_kit.dart';
import 'package:raindrop_client/features/identity/models/recovery_check.dart';
import 'package:raindrop_client/features/security/widgets/recovery_words_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _words = List.generate(24, (i) => 'word${String.fromCharCode(97 + i)}');

void main() {
  group('confirmationPositions', () {
    test('picks three distinct positions in order, within the words', () {
      for (var seed = 0; seed < 50; seed++) {
        final picked = confirmationPositions(24, random: Random(seed));
        expect(picked, hasLength(3));
        expect(picked.toSet(), hasLength(3));
        expect(picked, orderedEquals([...picked]..sort()));
        expect(picked.every((p) => p >= 0 && p < 24), isTrue);
      }
    });

    test('never asks for more words than there are', () {
      expect(confirmationPositions(2, random: Random(1)), [0, 1]);
    });
  });

  group('normalizing typed words', () {
    test('forgives case, spacing and numbering', () {
      expect(normalizeRecoveryWord('  Abandon '), 'abandon');
      expect(normalizeRecoveryWord('7. zoo'), 'zoo');
      expect(normalizeRecoveryWord('12)ability'), 'ability');
    });

    test('turns a pasted, numbered list into the words alone', () {
      expect(
        normalizeRecoveryWords('1. Abandon  2. ability\n3. able'),
        'abandon ability able',
      );
    });
  });

  group('recoveryCheckDue', () {
    final made = DateTime(2026, 1, 1);

    test('is due when this device never saw a check', () {
      expect(recoveryCheckDue(now: made), isTrue);
    });

    test('first comes a month after the words were made', () {
      expect(
        recoveryCheckDue(
          now: made.add(const Duration(days: 29)),
          setAt: made,
          checkedAt: made,
        ),
        isFalse,
      );
      expect(
        recoveryCheckDue(
          now: made.add(firstRecoveryReminder),
          setAt: made,
          checkedAt: made,
        ),
        isTrue,
      );
    });

    test('then every half year after a check', () {
      final checked = made.add(const Duration(days: 40));
      expect(
        recoveryCheckDue(
          now: checked.add(const Duration(days: 100)),
          setAt: made,
          checkedAt: checked,
        ),
        isFalse,
      );
      expect(
        recoveryCheckDue(
          now: checked.add(laterRecoveryReminder),
          setAt: made,
          checkedAt: checked,
        ),
        isTrue,
      );
    });
  });

  test('the emergency kit is a PDF', () async {
    final bytes = await buildEmergencyKit(
      words: _words,
      backupCodes: const ['ABCD-EFGH-JKLM', 'NPQR-STUV-WXYZ'],
      servers: const ['home.example:5001'],
      madeAt: DateTime(2026, 11, 19),
    );
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(
      emergencyKitFileName(DateTime(2026, 11, 19)),
      'raindrop-emergency-kit-2026-11-19.pdf',
    );
  });

  group('the recovery words dialog', () {
    Future<AppPrefs> open(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPrefs(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPrefsProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showRecoveryWordsDialog(context, _words.join(' ')),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I wrote them down'));
      await tester.pumpAndSettle();
      return prefs;
    }

    /// The positions the dialog asked for, read off its field labels.
    List<int> asked(WidgetTester tester) => [
      for (final field in tester.widgetList<TextField>(find.byType(TextField)))
        int.parse(field.decoration!.labelText!.split(' ').last) - 1,
    ];

    testWidgets('stays open until the asked-for words are typed back', (
      tester,
    ) async {
      final prefs = await open(tester);
      final positions = asked(tester);
      expect(positions, hasLength(3));

      final fields = find.byType(TextField);
      for (var i = 0; i < positions.length; i++) {
        await tester.enterText(fields.at(i), 'wrong');
      }
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Not all of those match'), findsOneWidget);
      expect(prefs.recoveryWordsSetAt, isNull);

      for (var i = 0; i < positions.length; i++) {
        await tester.enterText(
          fields.at(i),
          ' ${_words[positions[i]].toUpperCase()} ',
        );
      }
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Check you saved them'), findsNothing);
      expect(prefs.recoveryWordsSetAt, isNotNull);
      expect(prefs.recoveryCheckedAt, prefs.recoveryWordsSetAt);
    });

    testWidgets('can go back to the words', (tester) async {
      await open(tester);
      await tester.tap(find.text('Show the words again'));
      await tester.pumpAndSettle();
      expect(find.text('1. ${_words.first}'), findsOneWidget);
      expect(find.text('Save emergency kit'), findsOneWidget);
    });
  });

  test('a recovery wait is kept per server until it is cleared', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPrefs(await SharedPreferences.getInstance());
    final ends = DateTime.utc(2026, 11, 26, 12);

    await prefs.setRecoveryWait('a', ends);
    await prefs.setRecoveryWait('b', ends.add(const Duration(hours: 1)));
    expect(prefs.recoveryWaits['a'], ends);
    expect(prefs.recoveryWaits, hasLength(2));

    await prefs.setRecoveryWait('a', null);
    expect(prefs.recoveryWaits.keys, ['b']);
  });
}
