/// The server's push channel: `GET /api/events`, a WebSocket down which the
/// server sends every change this account is allowed to see. Mirrors
/// `RaindropServer/Events/` — see the server's `docs/events.md` for the
/// event catalogue and the close codes.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'api_client.dart';
import 'api_exception.dart';

/// The event names this build acts on. Like permissions and presence, events
/// travel by name, and one this client has never heard of is simply ignored —
/// that is what lets a newer server (or a server plugin) add its own.
abstract final class ServerEventTypes {
  static const ready = 'ready';
  static const messageCreated = 'message.created';
  static const messageDeleted = 'message.deleted';
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
}

/// One frame from the server: `{ "type": …, "data": { … } }`. [data] is left
/// as the decoded map so each feature parses it with the same `fromJson` it
/// already uses for the matching REST response — the payloads are the same
/// records.
class ServerEvent {
  const ServerEvent(this.type, this.data);

  final String type;
  final Map<String, dynamic> data;

  /// The `userId` most member events are about, for filtering on.
  String? get userId => data['userId'] as String?;

  /// The `channelId` channel and message events are about, for filtering on.
  String? get channelId => data['channelId'] as String?;
}

enum EventStreamStatus {
  /// Opening, or reopening after a drop.
  connecting,

  /// Open, and `ready` has arrived — from here on nothing is missed.
  live,

  /// Dropped; a reconnect is scheduled.
  disconnected,

  /// The server closed it because the session ended (`4401`), or refused to
  /// open it for an invalid token. It does not retry: the session has to be
  /// renewed first.
  sessionEnded,

  /// [EventStream.close] was called.
  closed,
}

/// Keeps the event stream to one server open for as long as it is wanted,
/// reconnecting with backoff whenever it drops.
///
/// It only ever delivers what the server sends; making sense of it is each
/// feature's business. The one rule every consumer has to follow is the
/// server's: events are notifications, not a source of truth, and nothing is
/// replayed — so after every `ready` (which [events] also delivers), re-read
/// whatever is on screen and merge, because anything that changed while the
/// stream was down was not sent.
class EventStream {
  EventStream(this._client, this._token);

  static const _path = '/api/events';

  /// The server's `WebSocketCloseCodes.SessionEnded`, numbered after HTTP 401.
  static const _sessionEndedCode = 4401;

  static const _maxBackoff = Duration(seconds: 30);

  final ApiClient _client;
  final String _token;
  final _random = Random();

  final _events = StreamController<ServerEvent>.broadcast();
  final _statuses = StreamController<EventStreamStatus>.broadcast();

  WebSocket? _socket;
  Completer<void>? _wake;
  bool _started = false;
  bool _closed = false;

  EventStreamStatus _status = EventStreamStatus.connecting;

  /// Every frame, `ready` included, in the order the server sent them.
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

  /// Closes the stream for good.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final wake = _wake;
    if (wake != null && !wake.isCompleted) wake.complete();
    await _socket?.close(WebSocketStatus.normalClosure);
    _setStatus(EventStreamStatus.closed);
    await _events.close();
    await _statuses.close();
  }

  Future<void> _run() async {
    var attempt = 0;

    while (!_closed) {
      _setStatus(EventStreamStatus.connecting);

      try {
        final socket = await _client.openWebSocket(_path, token: _token);
        if (_closed) {
          await socket.close(WebSocketStatus.normalClosure);
          return;
        }
        _socket = socket;

        await for (final frame in socket) {
          final event = _parse(frame);
          if (event == null) continue;
          if (event.type == ServerEventTypes.ready) {
            attempt = 0;
            _setStatus(EventStreamStatus.live);
          }
          if (!_events.isClosed) _events.add(event);
        }

        _socket = null;
        if (socket.closeCode == _sessionEndedCode) {
          _setStatus(EventStreamStatus.sessionEnded);
          return;
        }
      } on ApiException catch (e) {
        // The upgrade was refused with a body: a token the server no longer
        // knows is the one refusal retrying cannot fix.
        if (e.code == 'invalid_session' || e.code == 'missing_token') {
          _setStatus(EventStreamStatus.sessionEnded);
          return;
        }
      } on Object {
        // Dropped mid-stream, or never got through. Either way: back off and
        // try again.
        _socket = null;
      }

      if (_closed) return;
      _setStatus(EventStreamStatus.disconnected);
      await _sleep(_backoff(attempt++));
    }
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

  ServerEvent? _parse(Object? frame) {
    // The stream is opened asking for JSON, which the server sends in text
    // frames. A binary frame would be MessagePack, which this build does not
    // read yet — see the wire format doc.
    if (frame is! String) return null;
    try {
      final decoded = jsonDecode(frame);
      if (decoded is! Map || decoded['type'] is! String) return null;
      final data = decoded['data'];
      return ServerEvent(
        decoded['type'] as String,
        data is Map ? Map<String, dynamic>.from(data) : const {},
      );
    } on FormatException {
      return null;
    }
  }

  void _setStatus(EventStreamStatus status) {
    if (_status == status || _statuses.isClosed) return;
    _status = status;
    _statuses.add(status);
  }
}
