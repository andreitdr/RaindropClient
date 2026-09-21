/// Dart mirrors of the C# records in `RaindropServer/Channels/
/// ChannelContracts.cs`. JSON is camelCased by ASP.NET's default serializer,
/// so `ChannelId` on the wire is `channelId` here.
///
/// What lives inside a channel is per-type and stays out of this file, the
/// same way the server splits `Channels/` from `Channels/Text/` — see
/// `text_messages_api.dart`.
library;

import 'api_client.dart';

/// The wire names for a channel type. Anything else is a type this client is
/// too old to render, which is why [ChannelSummary.type] stays a string.
abstract final class ChannelTypeNames {
  static const text = 'text';
  static const voice = 'voice';
}

/// The permission names `ChannelSummary.yourPermissions` is drawn from, so
/// the UI can grey out what the server would refuse anyway. These mirror
/// `PermissionNames` in `RaindropServer/Roles/Permission.cs`; the server
/// resolves a member's roles into this list per channel, so the client never
/// has to know what a role is to know what it may do.
///
/// A server running a newer build may send a name that is not here, which is
/// why [ChannelSummary.yourPermissions] stays a list of strings — the extra
/// name is simply one this client does not act on. `GET /api/roles/permissions`
/// is where the full catalogue lives if a screen ever needs to render it.
abstract final class ChannelPermissionNames {
  static const viewChannel = 'view_channel';
  static const sendMessages = 'send_messages';
  static const manageMessages = 'manage_messages';
  static const createChannels = 'create_channels';
  static const renameChannels = 'rename_channels';
  static const deleteChannels = 'delete_channels';
  static const manageRoles = 'manage_roles';
  static const administrator = 'administrator';
  static const connect = 'connect';
  static const speak = 'speak';
  static const muteMembers = 'mute_members';
}

class ChannelSummary {
  const ChannelSummary({
    required this.channelId,
    required this.type,
    required this.name,
    required this.createdBy,
    required this.createdAtUtc,
    required this.yourPermissions,
  });

  final String channelId;
  final String type;
  final String name;
  final String createdBy;
  final DateTime createdAtUtc;
  final List<String> yourPermissions;

  bool get isText => type == ChannelTypeNames.text;

  bool can(String permission) => yourPermissions.contains(permission);

  factory ChannelSummary.fromJson(Map<String, dynamic> j) => ChannelSummary(
    channelId: j['channelId'] as String,
    type: j['type'] as String,
    name: j['name'] as String,
    createdBy: j['createdBy'] as String,
    createdAtUtc: DateTime.parse(j['createdAtUtc'] as String),
    yourPermissions: List<String>.from(
      j['yourPermissions'] as List? ?? const [],
    ),
  );
}

/// The answer to deleting a channel. The server describes what it did in
/// [message]; a client acts on [channelId], which is also what the
/// `channel.deleted` event carries.
class ChannelDeleted {
  const ChannelDeleted({required this.channelId, required this.message});

  final String channelId;
  final String message;

  factory ChannelDeleted.fromJson(Map<String, dynamic> j) => ChannelDeleted(
    channelId: j['channelId'] as String,
    message: j['message'] as String? ?? '',
  );
}

/// Typed wrapper over the `/api/channels` surface. One instance per
/// connected server, built from that server's [ApiClient].
class ChannelsApi {
  ChannelsApi(this._client);

  final ApiClient _client;

  /// Every channel on the server the caller may see, of every type, ordered
  /// by name — what the channel sidebar draws from.
  Future<List<ChannelSummary>> list(String token) async {
    final body = await _client.get('/api/channels', token: token);
    final channels = body['channels'] as List? ?? const [];
    return [
      for (final c in channels)
        ChannelSummary.fromJson(Map<String, dynamic>.from(c as Map)),
    ];
  }

  /// Creates a channel and returns it as the creator sees it. Needs the
  /// server-wide `create_channels` permission. The server refuses any
  /// [type] it has no module for with `channel_type_unsupported`.
  Future<ChannelSummary> create(
    String token, {
    required String name,
    String type = ChannelTypeNames.text,
  }) async => ChannelSummary.fromJson(
    await _client.post(
      '/api/channels/create',
      body: {'type': type, 'name': name},
      token: token,
    ),
  );

  /// Renames a channel. Needs `rename_channels` in it, which the channel's
  /// creator holds implicitly.
  Future<ChannelSummary> rename(
    String token, {
    required String channelId,
    required String name,
  }) async => ChannelSummary.fromJson(
    await _client.post(
      '/api/channels/rename',
      body: {'channelId': channelId, 'name': name},
      token: token,
    ),
  );

  /// Deletes a channel and every message in it. Needs `delete_channels` in
  /// it, which the channel's creator holds implicitly.
  Future<ChannelDeleted> delete(
    String token, {
    required String channelId,
  }) async => ChannelDeleted.fromJson(
    await _client.post(
      '/api/channels/delete',
      body: {'channelId': channelId},
      token: token,
    ),
  );
}
