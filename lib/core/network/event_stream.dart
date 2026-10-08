/// The server's push channel: `raindrop.v1.EventService/Connect`, a
/// bidirectional gRPC stream. The server sends every change this account is
/// allowed to see; this client sends a heartbeat every so often, which is
/// what keeps it online in everybody's roster, and a resubscribe when it wants
/// a fresh `ready`. See the server's `docs/events.md` for the event catalogue
/// and how a stream ends.
library;

import 'dart:async';
import 'dart:math';

import 'package:grpc/grpc.dart';

import 'grpc/protocol.dart' as pb;
import 'raindrop_channel.dart';

/// The names of the events this build acts on, as [ServerEvent.type] reports
/// them. On the wire each is one case of `raindrop.v1.ServerEvent`; inside the
/// app they keep the names the server publishes them under, so a feature's
/// `switch` reads the same as the server's docs. A case this build has never
/// heard of reads as [unknown] and is ignored.
abstract final class ServerEventTypes {
  static const ready = 'ready';
  static const messageCreated = 'message.created';
  static const messageDeleted = 'message.deleted';
  static const messageReported = 'message.reported';
  static const channelCreated = 'channel.created';
  static const channelRenamed = 'channel.renamed';
  static const channelDeleted = 'channel.deleted';
  static const memberJoined = 'member.joined';
  static const memberRenamed = 'member.renamed';
  static const memberLeft = 'member.left';
  static const memberPresence = 'member.presence';
  static const memberRoles = 'member.roles';
  static const roleCreated = 'role.created';
  static const roleUpdated = 'role.updated';
  static const roleDeleted = 'role.deleted';
  static const voiceState = 'voice.state';
  static const voiceLeft = 'voice.left';

  /// A case added on a newer server than this build.
  static const unknown = 'unknown';
}

/// One event from the server: [proto] is the typed message, and [type],
/// [userId] and [channelId] are what most consumers filter on before they
/// read the case they care about from it.
///
/// A plugin's event is `plugin`: its [type] is the plugin's own name for it,
/// and its payload is the plugin's protobuf message in `proto.plugin.data`.
class ServerEvent {
  const ServerEvent(this.proto);

  final pb.ServerEvent proto;

  /// The event's name — one of [ServerEventTypes] or `E2eeEventTypes`, or a
  /// plugin's.
  String get type => switch (proto.whichEvent()) {
    pb.ServerEvent_Event.ready => ServerEventTypes.ready,
    pb.ServerEvent_Event.messageCreated => ServerEventTypes.messageCreated,
    pb.ServerEvent_Event.messageDeleted => ServerEventTypes.messageDeleted,
    pb.ServerEvent_Event.messageReported => ServerEventTypes.messageReported,
    pb.ServerEvent_Event.channelCreated => ServerEventTypes.channelCreated,
    pb.ServerEvent_Event.channelRenamed => ServerEventTypes.channelRenamed,
    pb.ServerEvent_Event.channelDeleted => ServerEventTypes.channelDeleted,
    pb.ServerEvent_Event.memberJoined => ServerEventTypes.memberJoined,
    pb.ServerEvent_Event.memberRenamed => ServerEventTypes.memberRenamed,
    pb.ServerEvent_Event.memberLeft => ServerEventTypes.memberLeft,
    pb.ServerEvent_Event.memberPresence => ServerEventTypes.memberPresence,
    pb.ServerEvent_Event.memberRoles => ServerEventTypes.memberRoles,
    pb.ServerEvent_Event.roleCreated => ServerEventTypes.roleCreated,
    pb.ServerEvent_Event.roleUpdated => ServerEventTypes.roleUpdated,
    pb.ServerEvent_Event.roleDeleted => ServerEventTypes.roleDeleted,
    pb.ServerEvent_Event.voiceState => ServerEventTypes.voiceState,
    pb.ServerEvent_Event.voiceLeft => ServerEventTypes.voiceLeft,
    pb.ServerEvent_Event.deviceAdded => 'e2ee.device.added',
    pb.ServerEvent_Event.deviceRevoked => 'e2ee.device.revoked',
    pb.ServerEvent_Event.identityReset => 'e2ee.identity.reset',
    pb.ServerEvent_Event.handshake => 'e2ee.handshake',
    pb.ServerEvent_Event.welcome => 'e2ee.welcome',
    pb.ServerEvent_Event.groupReconcile => 'e2ee.group.reconcile',
    pb.ServerEvent_Event.keyPackagesLow => 'e2ee.keypackages.low',
    pb.ServerEvent_Event.plugin => proto.plugin.type,
    pb.ServerEvent_Event.notSet => ServerEventTypes.unknown,
  };

  /// The member the event is about, for filtering on; null for events that
  /// are not about one.
  String? get userId => switch (proto.whichEvent()) {
    pb.ServerEvent_Event.ready => proto.ready.userId,
    pb.ServerEvent_Event.memberJoined => proto.memberJoined.userId,
    pb.ServerEvent_Event.memberRenamed => proto.memberRenamed.userId,
    pb.ServerEvent_Event.memberLeft => proto.memberLeft.userId,
    pb.ServerEvent_Event.memberPresence => proto.memberPresence.userId,
    pb.ServerEvent_Event.memberRoles => proto.memberRoles.userId,
    pb.ServerEvent_Event.voiceState => proto.voiceState.userId,
    pb.ServerEvent_Event.voiceLeft => proto.voiceLeft.userId,
    pb.ServerEvent_Event.deviceAdded => proto.deviceAdded.userId,
    pb.ServerEvent_Event.deviceRevoked => proto.deviceRevoked.userId,
    pb.ServerEvent_Event.identityReset => proto.identityReset.userId,
    _ => null,
  };

  /// The channel the event is about, for filtering on; null for events that
  /// are not about one.
  String? get channelId => switch (proto.whichEvent()) {
    pb.ServerEvent_Event.messageCreated => proto.messageCreated.channelId,
    pb.ServerEvent_Event.messageDeleted => proto.messageDeleted.channelId,
    pb.ServerEvent_Event.messageReported => proto.messageReported.channelId,
    pb.ServerEvent_Event.channelCreated => proto.channelCreated.channelId,
    pb.ServerEvent_Event.channelRenamed => proto.channelRenamed.channelId,
    pb.ServerEvent_Event.channelDeleted => proto.channelDeleted.channelId,
    pb.ServerEvent_Event.voiceState => proto.voiceState.channelId,
    pb.ServerEvent_Event.voiceLeft => proto.voiceLeft.channelId,
    pb.ServerEvent_Event.handshake => proto.handshake.channelId,
    pb.ServerEvent_Event.welcome => proto.welcome.channelId,
    pb.ServerEvent_Event.groupReconcile => proto.groupReconcile.channelId,
    _ => null,
  };
}

enum EventStreamStatus {
  /// Opening, or reopening after a drop.
  connecting,

  /// Open, and `ready` has arrived — from here on nothing is missed.
  live,

  /// Dropped; a reconnect is scheduled.
  disconnected,

  /// The server ended it because the session ended (`session_ended`), or
  /// refused to open it for an invalid token. It does not retry: the session
  /// has to be renewed first.
  sessionEnded,

  /// [EventStream.close] was called.
  closed,
}

/// Keeps the event stream to one server open for as long as it is wanted,
/// reconnecting with backoff whenever it drops, and heartbeating on it so the
/// server knows this client is still here.
///
/// It only ever delivers what the server sends; making sense of it is each
/// feature's business. The one rule every consumer has to follow is the
/// server's: events are notifications, not a source of truth, and nothing is
/// replayed — so after every `ready` (which [events] also delivers), re-read
/// whatever is on screen and merge, because anything that changed while the
/// stream was down was not sent.
class EventStream {
  EventStream(this._channel, this._token)
    : _events_ = pb.EventServiceClient(_channel.channel);

  /// What the stream is ended with when the session behind it is gone — the
  /// one ending retrying cannot fix.
  static const _sessionEnded = {
    'session_ended',
    'invalid_session',
    'missing_token',
  };

  static const _maxBackoff = Duration(seconds: 30);

  /// Used until the server's `ready` says otherwise.
  static const _defaultHeartbeat = Duration(seconds: 20);

  final RaindropChannel _channel;
  final pb.EventServiceClient _events_;
  final String _token;
  final _random = Random();

  final _events = StreamController<ServerEvent>.broadcast();
  final _statuses = StreamController<EventStreamStatus>.broadcast();

  StreamController<pb.ConnectRequest>? _requests;
  ResponseStream<pb.ConnectResponse>? _call;
  Timer? _heartbeat;
  Completer<void>? _wake;
  bool _started = false;
  bool _closed = false;

  EventStreamStatus _status = EventStreamStatus.connecting;

  /// Every event, `ready` included, in the order the server sent them.
  Stream<ServerEvent> get events => _events.stream;

  /// Each change of [status].
  Stream<EventStreamStatus> get statusChanges => _statuses.stream;

  EventStreamStatus get status => _status;

  /// True while events are arriving; when false, anything that must stay
  /// current has to fall back to polling.
  bool get isLive => _status == EventStreamStatus.live;

  /// Starts connecting. Calling it again does nothing.
  void start() {
    if (_started || _closed) return;
    _started = true;
    unawaited(_run());
  }

  /// Asks the server for a fresh `ready` on the open stream — what to do when
  /// the app comes back from the background, so everything re-reads without
  /// the stream being torn down. Does nothing while the stream is not open.
  void resubscribe() {
    if (!isLive) return;
    _send(pb.ConnectRequest(resubscribe: pb.Resubscribe()));
  }

  /// Closes the stream for good.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final wake = _wake;
    if (wake != null && !wake.isCompleted) wake.complete();
    _heartbeat?.cancel();
    await _requests?.close();
    await _call?.cancel();
    _setStatus(EventStreamStatus.closed);
    await _events.close();
    await _statuses.close();
  }

  Future<void> _run() async {
    var attempt = 0;

    while (!_closed) {
      _setStatus(EventStreamStatus.connecting);

      final requests = _requests = StreamController<pb.ConnectRequest>();
      final call = _call = _events_.connect(
        requests.stream,
        options: _channel.options(token: _token, timeout: null),
      );

      try {
        await for (final response in call) {
          final event = ServerEvent(response.event);
          if (event.type == ServerEventTypes.ready) {
            attempt = 0;
            _startHeartbeat(response.event.ready);
            _setStatus(EventStreamStatus.live);
          }
          if (!_events.isClosed) _events.add(event);
        }
        // The server only ends a stream with OK when this client ended its
        // own half; otherwise it is a drop like any other.
      } on Object catch (error) {
        if (_closed) return;
        final failure = _channel.translate(error);
        if (_sessionEnded.contains(failure.code)) {
          _stopStream();
          _setStatus(EventStreamStatus.sessionEnded);
          return;
        }
      }

      _stopStream();
      if (_closed) return;
      _setStatus(EventStreamStatus.disconnected);
      await _sleep(_backoff(attempt++));
    }
  }

  /// Heartbeats every [ready]'s interval (the server ends a stream it has not
  /// heard from in a few of them), starting at once so a slow `ready` cannot
  /// eat into the first one.
  void _startHeartbeat(pb.ReadyEvent ready) {
    final interval = ready.hasHeartbeatInterval()
        ? ready.heartbeatInterval.toDart()
        : _defaultHeartbeat;
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      interval > Duration.zero ? interval : _defaultHeartbeat,
      (_) => _send(pb.ConnectRequest(heartbeat: pb.Heartbeat())),
    );
  }

  void _send(pb.ConnectRequest frame) {
    final requests = _requests;
    if (requests != null && !requests.isClosed) requests.add(frame);
  }

  void _stopStream() {
    _heartbeat?.cancel();
    _heartbeat = null;
    unawaited(_requests?.close());
    _requests = null;
    _call = null;
  }

  /// 1s, 2s, 4s … capped at [_maxBackoff], with jitter so that every client
  /// of a server that has just restarted does not reconnect in the same
  /// instant.
  Duration _backoff(int attempt) {
    final base = Duration(seconds: 1 << min(attempt, 5));
    final capped = base > _maxBackoff ? _maxBackoff : base;
    final jitter = _random.nextInt(capped.inMilliseconds ~/ 2 + 1);
    return Duration(milliseconds: capped.inMilliseconds ~/ 2 + jitter);
  }

  /// A sleep [close] can cut short.
  Future<void> _sleep(Duration duration) {
    final wake = _wake = Completer<void>();
    final timer = Timer(duration, () {
      if (!wake.isCompleted) wake.complete();
    });
    return wake.future.whenComplete(timer.cancel);
  }

  void _setStatus(EventStreamStatus status) {
    if (_status == status || _statuses.isClosed) return;
    _status = status;
    _statuses.add(status);
  }
}
