/// The rules a channel name must satisfy, mirroring `ChannelNamePolicy` in
/// `RaindropServer/Channels/ChannelNamePolicy.cs`.
///
/// This exists only so the name dialog can say what is wrong before a round
/// trip. The server stays the authority — it also enforces uniqueness, which
/// no client can — and whatever it answers is shown as-is, so a server whose
/// policy differs from this copy still gets its own message across.
const kChannelNameMinLength = 2;
const kChannelNameMaxLength = 64;

/// Why [name] is not an acceptable channel name, or null when it is. The
/// name is judged trimmed, as the server does.
String? validateChannelName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return 'A channel name is required.';

  if (trimmed.length < kChannelNameMinLength ||
      trimmed.length > kChannelNameMaxLength) {
    return 'A channel name must be between $kChannelNameMinLength and '
        '$kChannelNameMaxLength characters long.';
  }

  if (!_allowed.hasMatch(trimmed)) {
    return 'A channel name may only contain letters, digits, and the '
        'characters _ . -';
  }

  if (!_alphanumeric.hasMatch(trimmed[0]) ||
      !_alphanumeric.hasMatch(trimmed[trimmed.length - 1])) {
    return 'A channel name must start and end with a letter or a digit.';
  }

  return null;
}

final _allowed = RegExp(r'^[A-Za-z0-9_.\-]+$');
final _alphanumeric = RegExp(r'^[A-Za-z0-9]$');
