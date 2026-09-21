import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/event_stream.dart';
import 'session_controller.dart';

/// The live event stream for one connected server, open for as long as that
/// server has a session — whether or not any pane showing it is on screen, so
/// presence and unread state have something to follow. Null when not signed
/// in there.
///
/// A new session (a fresh login, a changed token) is a new stream: the old
/// one's token is gone, and the server would close it anyway.
final serverEventsProvider = Provider.family<EventStream?, String>((
  ref,
  serverId,
) {
  final session = ref.watch(serverSessionProvider(serverId)).valueOrNull;
  if (session == null) return null;

  final stream = EventStream(session.client, session.token)..start();

  // The server closes the stream when the session behind it ends — logged out
  // or revoked elsewhere. Re-resolving the session is what routes the shell to
  // the reauth prompt: it re-checks the token and finds it gone.
  final statuses = stream.statusChanges.listen((status) {
    if (status == EventStreamStatus.sessionEnded) {
      ref.invalidate(serverSessionProvider(serverId));
    }
  });

  ref.onDispose(() {
    unawaited(statuses.cancel());
    unawaited(stream.close());
  });
  return stream;
});
