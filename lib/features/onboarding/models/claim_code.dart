/// A claim code the owner of a server issued from its console (`reclaim`):
/// the last way back for a person who lost every device, their recovery
/// words and any backup. Their new identity redeems it to take over the
/// account it names — `RDC1-<account id>-<secret>`.
class ClaimCode {
  const ClaimCode._(this.accountId, this.text);

  /// The account the code hands over: the new identity's device certifies
  /// itself for this id rather than the one its root derives.
  final String accountId;

  /// The code as the server reads it.
  final String text;

  static final _pattern = RegExp(
    r'^rdc1-([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})-([0-9a-f]{32})$',
  );

  /// Reads a typed or pasted code, forgiving case and spaces; null for
  /// anything that is not one.
  static ClaimCode? tryParse(String typed) {
    final text = typed.replaceAll(RegExp(r'\s'), '').toLowerCase();
    final match = _pattern.firstMatch(text);
    return match == null ? null : ClaimCode._(match.group(1)!, text);
  }
}
