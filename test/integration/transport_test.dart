// The gRPC transport against a live RaindropServer: the handshake and the
// certificate pin, how a refusal arrives, and the event stream — ready, pushed
// events, resubscribe, presence, and the session ending. Needs no Rust core, so
// it runs wherever a server does:
//
//   RAINDROP_TEST_SERVER=localhost:5001 flutter test test/integration/transport_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raindrop_client/core/network/api_exception.dart';
import 'package:raindrop_client/core/network/channels_api.dart';
import 'package:raindrop_client/core/network/event_stream.dart';
import 'package:raindrop_client/core/network/members_api.dart';
import 'package:raindrop_client/core/network/raindrop_channel.dart';
import 'package:raindrop_client/core/network/server_trust.dart';
import 'package:raindrop_client/core/network/users_api.dart';
import 'package:raindrop_client/core/network/voice_api.dart';
import 'package:uuid/uuid.dart';

final _server = Platform.environment['RAINDROP_TEST_SERVER'];
final _skip = _server == null ? 'set RAINDROP_TEST_SERVER' : null;

const _uuid = Uuid();

Matcher _apiError(String code) =>
    throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

RaindropChannel _connect({String? pinned}) {
  final parts = _server!.split(':');
  return RaindropChannel.forServer(
    host: parts[0],
    port: int.parse(parts[1]),
    pinnedFingerprint: pinned,
  );
}

/// The next event on [stream] that [test] accepts.
Future<ServerEvent> _next(
  EventStream stream,
  bool Function(ServerEvent event) test,
) => stream.events.firstWhere(test).timeout(const Duration(seconds: 10));

void main() {
  late RaindropChannel client;
  late UsersApi users;

  setUpAll(() {
    if (_skip != null) return;
    client = _connect();
    users = UsersApi(client);
  });

  tearDownAll(() async {
    if (_skip == null) await client.close();
  });

  Future<SessionResult> register(String name) => users.register(
    userId: _uuid.v4(),
    username: '$name${DateTime.now().microsecondsSinceEpoch % 100000000}',
    password: 'correct horse battery',
  );

  test(
    'the handshake pins the certificate it saw, and a wrong pin is refused',
    () async {
      final info = await users.serverInfo();
      expect(info.protocolVersion, '2');

      final presented = client.pinner.observedFingerprint;
      expect(
        presented,
        isNotNull,
        reason: 'a self-signed certificate goes through the pinner',
      );
      expect(ServerTrust.isConsistent(info, presented!), isTrue);

      // The same certificate under its pin is accepted…
      final pinned = _connect(pinned: presented);
      addTearDown(pinned.close);
      expect(
        (await UsersApi(pinned).serverInfo()).tlsFingerprint,
        info.tlsFingerprint,
      );

      // …and any other pin is a mismatch, not a network error.
      final wrong = _connect(pinned: 'ab' * 32);
      addTearDown(wrong.close);
      await expectLater(
        UsersApi(wrong).serverInfo(),
        _apiError('certificate_mismatch'),
      );
    },
    skip: _skip,
  );

  test(
    'a refusal arrives as its error code and a message for people',
    () async {
      final alice = await register('alice');

      await expectLater(
        users.register(
          userId: _uuid.v4(),
          username: alice.user.username,
          password: 'correct horse battery',
        ),
        _apiError('username_taken'),
      );
      await expectLater(users.me('not-a-token'), _apiError('invalid_session'));

      try {
        await ChannelsApi(client)
            .rename(alice.token, channelId: 'nope', name: 'x');
        fail('a malformed id was accepted');
      } on ApiException catch (e) {
        expect(e.code, 'invalid_payload');
        expect(e.message, contains('channel_id'));
      }

      expect((await users.me(alice.token)).username, alice.user.username);
      expect(
        (await VoiceApi(client).status(alice.token)).transport,
        isNotEmpty,
      );
    },
    skip: _skip,
  );

  test('the event stream: ready, pushed changes, resubscribe, presence and the session ending', () async {
    final alice = await register('alice');
    final members = MembersApi(client);

    Future<String> presence() async =>
        (await members.list(alice.token))
            .firstWhere((m) => m.userId == alice.user.userId)
            .presence;

    // Signed in, but not listening: not around.
    expect(await presence(), PresenceStatusNames.offline);

    final stream = EventStream(client, alice.token);
    addTearDown(stream.close);
    final ready = _next(stream, (e) => e.type == ServerEventTypes.ready);
    stream.start();

    final first = await ready;
    expect(first.userId, alice.user.userId);
    expect(
      first.proto.ready.heartbeatInterval.toDart(),
      greaterThan(Duration.zero),
    );
    // Live is set before ready is handed on, so it already holds.
    expect(stream.isLive, isTrue);

    // Listening is being around.
    expect(await presence(), PresenceStatusNames.online);

    // A change is pushed, typed, and readable with the same model a call returns.
    final name = 'general-${DateTime.now().microsecondsSinceEpoch % 100000000}';
    final created = _next(
      stream,
      (e) =>
          e.type == ServerEventTypes.channelCreated &&
          e.proto.channelCreated.name == name,
    );
    final channel = await ChannelsApi(client).create(alice.token, name: name);
    final event = await created;
    expect(event.channelId, channel.channelId);
    expect(ChannelSummary.fromProto(event.proto.channelCreated).name, name);

    // Resubscribing asks for a fresh ready on the same stream.
    final again = _next(stream, (e) => e.type == ServerEventTypes.ready);
    stream.resubscribe();
    await again;

    // Logging out ends the stream as the session ending, which is not retried.
    final ended = stream.statusChanges
        .firstWhere((s) => s == EventStreamStatus.sessionEnded)
        .timeout(const Duration(seconds: 10));
    await users.logout(alice.token);
    await ended;
  }, skip: _skip);
}
