import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';

/// Which channel the user last picked, or null before they have picked one.
///
/// It is deliberately *only* the user's choice, not the resolved channel:
/// the id may belong to another server, or to a channel that has since been
/// deleted, so whoever renders the chat pane resolves it against the loaded
/// list with [resolveChannel] and falls back to the first one available.
final selectedChannelIdProvider =
    NotifierProvider<SelectedChannelController, String?>(
      SelectedChannelController.new,
    );

class SelectedChannelController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String channelId) => state = channelId;
}

/// The channel to actually show: the selected one if it is in [channels],
/// otherwise the first text channel, otherwise the first channel of any
/// kind. Null only when the server has no channels at all.
Channel? resolveChannel(List<Channel> channels, String? selectedId) {
  if (channels.isEmpty) return null;
  for (final channel in channels) {
    if (channel.id == selectedId) return channel;
  }
  return channels.firstWhere(
    (c) => c.type == ChannelType.text,
    orElse: () => channels.first,
  );
}
