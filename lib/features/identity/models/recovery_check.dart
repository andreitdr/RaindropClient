import 'dart:math';

/// How many of the words the person retypes to show they wrote them down.
const recoveryConfirmCount = 3;

/// The first reminder comes this long after the words were made: soon
/// enough that a lost note is noticed while a device still works.
const firstRecoveryReminder = Duration(days: 30);

/// After that, a check every half year.
const laterRecoveryReminder = Duration(days: 182);

/// Which word positions (0-based, ascending) to ask for when confirming a
/// recovery key of [wordCount] words. Different every time, so the person
/// cannot pass by remembering the last answer.
List<int> confirmationPositions(
  int wordCount, {
  int count = recoveryConfirmCount,
  Random? random,
}) {
  final rng = random ?? Random.secure();
  final picked = <int>{};
  while (picked.length < min(count, wordCount)) {
    picked.add(rng.nextInt(wordCount));
  }
  return picked.toList()..sort();
}

/// One word as typed, the way the recovery words are compared: case,
/// surrounding space and a leading "7." or "7)" numbering forgiven.
String normalizeRecoveryWord(String typed) =>
    typed.trim().toLowerCase().replaceFirst(RegExp(r'^\d+\s*[.)]\s*'), '');

/// The whole set of words as typed or pasted, ready for the Rust core: one
/// space between words, numbering forgiven, lower case.
String normalizeRecoveryWords(String typed) => typed
    .trim()
    .split(RegExp(r'\s+'))
    .map(normalizeRecoveryWord)
    .where((word) => word.isNotEmpty)
    .join(' ');

/// Whether the person should be asked to check their recovery words.
///
/// [setAt] is when the current words were shown and confirmed; [checkedAt]
/// when the person last showed they still have them (making them counts).
/// Never checked on this device means now. The first reminder is a month
/// after the words were made; every one after that, half a year.
bool recoveryCheckDue({
  required DateTime now,
  DateTime? setAt,
  DateTime? checkedAt,
}) {
  if (checkedAt == null) return true;
  final firstCheckSinceMade = setAt != null && !checkedAt.isAfter(setAt);
  final interval = firstCheckSinceMade
      ? firstRecoveryReminder
      : laterRecoveryReminder;
  return !now.isBefore(checkedAt.add(interval));
}
