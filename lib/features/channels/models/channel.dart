import '../../../core/network/channels_api.dart';

/// The channel types this client knows how to render. [unknown] is what a
/// type added to a newer server than this build arrives as — it is listed
/// and greyed out rather than crashing the sidebar.
enum ChannelType { text, voice, unknown }

/// A channel as the UI needs it: the server's [ChannelSummary] reduced to
/// what the sidebar and chat pane actually read, with the permission strings
/// resolved into the questions this feature asks of them.
class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.type,
    this.canSendMessages = false,
    this.canRename = false,
    this.canDelete = false,
    this.canManageMessages = false,
    this.canConnect = false,
    this.canSpeak = false,
    this.canAttachFiles = false,
  });

  final String id;
  final String name;
  final ChannelType type;

  /// Whether the server would accept a message from us here. The composer is
  /// disabled when it wouldn't, rather than letting the send fail with a 403.
  final bool canSendMessages;

  /// Whether we may rename this channel. The server counts its creator as
  /// holding this whatever their roles say, and reports it that way.
  final bool canRename;

  /// Whether we may delete this channel and everything in it.
  final bool canDelete;

  /// Whether we may delete *other* members' messages here. Deleting our own
  /// needs no permission at all, so this never gates that.
  final bool canManageMessages;

  /// Whether we may join this channel's call. Only meaningful for voice.
  final bool canConnect;

  /// Whether we would be heard in this channel's call, rather than only
  /// listening. The server can still mute somebody for everyone on top.
  final bool canSpeak;

  /// Whether we may add files to the messages we post here. The composer
  /// hides its attach button when we may not.
  final bool canAttachFiles;

  factory Channel.fromSummary(ChannelSummary summary) => Channel(
    id: summary.channelId,
    name: summary.name,
    type: switch (summary.type) {
      ChannelTypeNames.text => ChannelType.text,
      ChannelTypeNames.voice => ChannelType.voice,
      _ => ChannelType.unknown,
    },
    canSendMessages: summary.can(ChannelPermissionNames.sendMessages),
    canRename: summary.can(ChannelPermissionNames.renameChannels),
    canDelete: summary.can(ChannelPermissionNames.deleteChannels),
    canManageMessages: summary.can(ChannelPermissionNames.manageMessages),
    canConnect: summary.can(ChannelPermissionNames.connect),
    canSpeak: summary.can(ChannelPermissionNames.speak),
    canAttachFiles: summary.can(ChannelPermissionNames.attachFiles),
  );
}

class ChannelCategory {
  const ChannelCategory({
    required this.type,
    required this.title,
    required this.channels,
  });

  final ChannelType type;
  final String title;
  final List<Channel> channels;
}

/// Groups a server's channel list by type for the sidebar. The server
/// already orders channels by name and has no concept of categories, so the
/// grouping is entirely a client-side presentation choice; empty groups are
/// dropped so a server with no voice channels shows no voice heading —
/// except the text and voice groups when [alwaysShowText] and
/// [alwaysShowVoice] are set, which is where a member who may create
/// channels finds the button to create one of that kind.
List<ChannelCategory> groupByType(
  List<Channel> channels, {
  bool alwaysShowText = false,
  bool alwaysShowVoice = false,
}) {
  const titles = {
    ChannelType.text: 'Text Channels',
    ChannelType.voice: 'Voice Channels',
    ChannelType.unknown: 'Other',
  };
  return [
    for (final type in ChannelType.values)
      if (channels.any((c) => c.type == type) ||
          (alwaysShowText && type == ChannelType.text) ||
          (alwaysShowVoice && type == ChannelType.voice))
        ChannelCategory(
          type: type,
          title: titles[type]!,
          channels: channels.where((c) => c.type == type).toList(),
        ),
  ];
}
