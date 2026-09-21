import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/event_stream.dart';
import 'server_events.dart';

/// Keeps one controller's state in step with its server: hands it each event
/// as it arrives, asks it to re-read whenever the stream (re)connects, and
/// falls back to polling only while the stream is down.
///
/// The re-read on `ready` is not optional. The server replays nothing, so
/// whatever changed while the stream was down is only picked up by reading it
/// again — and doing it *after* `ready` is what guarantees there is no gap,
/// since anything that changes after that arrives as an event.
///
/// The fallback poll is what keeps a client working against a server too old
/// to have `/api/events`, or through a network that drops WebSockets: the
/// stream keeps retrying in the background, and the moment it is live the
/// poll stops.
class LiveSync {
  LiveSync(
    Ref ref, {
    required String serverId,
    required void Function(ServerEvent event) onEvent,
    required this._resync,
    this._fallbackPoll,
  }) {
    final stream = ref.read(serverEventsProvider(serverId));
    ref.onDispose(_dispose);

    if (stream == null) {
      _startPolling();
      return;
    }

    _subscriptions.add(
      stream.events.listen((event) {
        if (event.type == ServerEventTypes.ready) {
          unawaited(_resync());
        } else {
          onEvent(event);
        }
      }),
    );
    _subscriptions.add(
      stream.statusChanges.listen(
        (status) =>
            status == EventStreamStatus.live ? _stopPolling() : _startPolling(),
      ),
    );

    if (!stream.isLive) _startPolling();
  }

  final Future<void> Function() _resync;
  final Duration? _fallbackPoll;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _poll;

  /// Whether updates are currently arriving by push rather than by polling.
  bool get isPolling => _poll != null;

  void _startPolling() {
    final interval = _fallbackPoll;
    if (interval == null || _poll != null) return;
    _poll = Timer.periodic(interval, (_) => unawaited(_resync()));
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  void _dispose() {
    _stopPolling();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
  }
}
