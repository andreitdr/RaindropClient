import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../../../core/network/api_exception.dart';
import '../../../core/network/event_stream.dart';
import '../../../core/network/users_api.dart';
import 'server_events.dart';
import 'session_controller.dart';

/// Which UUID on which server is being asked about.
typedef UserRef = ({String serverId, String userId});

/// Resolves a UUID into something to show, through `POST /api/users/lookup`.
///
/// Messages carry their author's UUID and nothing else, so every message row
/// needs this. Riverpod's per-argument caching is the cache: one request per
/// distinct author for as long as the app is running, however many messages
/// that author wrote. Null means the lookup failed — the caller falls back
/// to a shortened UUID rather than showing an error in the message list.
///
/// The cache follows the event stream: when this member is renamed, leaves or
/// rejoins, the entry is dropped and looked up again, so every message they
/// wrote shows the new name without anything re-reading history.
final userLookupProvider = FutureProvider.family<PublicUserProfile?, UserRef>((
  ref,
  who,
) async {
  final session = await ref.watch(serverSessionProvider(who.serverId).future);
  if (session == null) return null;

  final events = ref.watch(serverEventsProvider(who.serverId));
  if (events != null) {
    final changes = events.events
        .where(
          (e) =>
              e.userId == who.userId &&
              (e.type == ServerEventTypes.memberRenamed ||
                  e.type == ServerEventTypes.memberLeft ||
                  e.type == ServerEventTypes.memberJoined),
        )
        .listen((_) => ref.invalidateSelf());
    ref.onDispose(() => unawaited(changes.cancel()));
  }
  try {
    return await session.usersApi.lookup(session.token, who.userId);
  } on ApiException {
    return null;
  }
});

/// The best name available for [userId] right now: the looked-up username,
/// `Unknown` for an erased account the server has no name for any more, or a
/// short prefix of the UUID while the lookup is still in flight.
String displayNameFor(WidgetRef ref, UserRef who) {
  final profile = ref.watch(userLookupProvider(who)).valueOrNull;
  if (profile == null) return who.userId.split('-').first;
  return profile.username ?? 'Unknown';
}
