/// The app's view of `raindrop.v1.ChannelService` (RaindropProto's
/// `channels.proto`).
///
/// What lives inside a channel is per-type and stays out of this file, the
/// same way the server splits `Channels/` from `Channels/Text/` — see
/// `text_messages_api.dart`.
library;

import 'grpc/protocol.dart' as pb;
import 'grpc/wire.dart';
import 'raindrop_channel.dart';

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
/// name is simply one this client does not act on. `RoleService.ListPermissions`
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
  static const attachFiles = 'attach_files';
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

  factory ChannelSummary.fromProto(pb.Channel m) => ChannelSummary(
    channelId: m.channelId,
    type: m.type,
    name: m.name,
    createdBy: m.createdBy,
    createdAtUtc: Wire.time(m.createdAt),
    yourPermissions: List.unmodifiable(m.yourPermissions),
  );
}

/// The answer to deleting a channel. The server describes what it did in
/// [message]; a client acts on [channelId], which is also what the
/// `channel.deleted` event carries.
class ChannelDeleted {
  const ChannelDeleted({required this.channelId, required this.message});

  final String channelId;
  final String message;

  factory ChannelDeleted.fromProto(pb.DeleteChannelResponse m) =>
      ChannelDeleted(channelId: m.channelId, message: m.message);
}

/// `raindrop.v1.ChannelService`. One instance per connected server, built on
/// that server's [RaindropChannel].
class ChannelsApi {
  ChannelsApi(this._channel)
    : _channels = pb.ChannelServiceClient(_channel.channel);

  final RaindropChannel _channel;
  final pb.ChannelServiceClient _channels;

  /// Every channel on the server the caller may see, of every type, ordered
  /// by name — what the channel sidebar draws from.
  Future<List<ChannelSummary>> list(String token) async {
    final response = await _channel.call(
      (o) => _channels.listChannels(pb.ListChannelsRequest(), options: o),
      token: token,
    );
    return [for (final c in response.channels) ChannelSummary.fromProto(c)];
  }

  /// Creates a channel and returns it as the creator sees it. Needs the
  /// server-wide `create_channels` permission. The server refuses any
  /// [type] it has no module for with `channel_type_unsupported`.
  Future<ChannelSummary> create(
    String token, {
    required String name,
    String type = ChannelTypeNames.text,
  }) async => ChannelSummary.fromProto(
    (await _channel.call(
      (o) => _channels.createChannel(
        pb.CreateChannelRequest(type: type, name: name),
        options: o,
      ),
      token: token,
    )).channel,
  );

  /// Renames a channel. Needs `rename_channels` in it, which the channel's
  /// creator holds implicitly.
  Future<ChannelSummary> rename(
    String token, {
    required String channelId,
    required String name,
  }) async => ChannelSummary.fromProto(
    (await _channel.call(
      (o) => _channels.renameChannel(
        pb.RenameChannelRequest(channelId: channelId, name: name),
        options: o,
      ),
      token: token,
    )).channel,
  );

  /// Deletes a channel and every message in it. Needs `delete_channels` in
  /// it, which the channel's creator holds implicitly.
  Future<ChannelDeleted> delete(
    String token, {
    required String channelId,
  }) async => ChannelDeleted.fromProto(
    await _channel.call(
      (o) => _channels.deleteChannel(
        pb.DeleteChannelRequest(channelId: channelId),
        options: o,
      ),
      token: token,
    ),
  );
}
