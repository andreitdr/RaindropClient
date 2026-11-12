/// Keeping a call running while the app is not on screen.
///
/// Phones stop an app that leaves the foreground, and a call stopped with it
/// — the microphone closes and the media connection drops. The two mobile
/// platforms ask for opposite things, so neither the call controller nor the
/// voice engine says any of it out loud:
///
/// * **iOS** needs nothing at runtime. The `audio` background mode in
///   `ios/Runner/Info.plist` plus the `playAndRecord` audio session LiveKit
///   already sets is the whole arrangement, so this is inert there.
/// * **Android** needs a foreground service of type `microphone`, with a
///   notification, for as long as the call lasts — see
///   `android/app/src/main/kotlin/.../CallForegroundService.kt`.
/// * **Desktop** windows are never stopped for being in the background.
///
/// [CallSessionHost] is the seam between those: the call controller begins a
/// session when a call starts, renames it when the call moves, and ends it
/// when the call does. A platform with nothing to do gets [InactiveCallSessionHost],
/// not a branch at the call site.
library;

import 'package:flutter/services.dart';

import '../platform/platform_info.dart';

/// What the OS shows about the call it is being asked to keep alive. Android
/// puts these in the ongoing notification; a host that shows nothing ignores
/// them.
class CallSessionDescription {
  const CallSessionDescription({required this.title, required this.body});

  /// The call, in a few words — the channel being talked in.
  final String title;

  /// Where that channel is: the server's name.
  final String body;

  @override
  bool operator ==(Object other) =>
      other is CallSessionDescription &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(title, body);
}

/// Tells the OS a call is in progress, for as long as one is.
///
/// Every method is safe to call in any order and any number of times:
/// [begin] twice describes the same session twice rather than opening a
/// second one, and [end] with no session running does nothing. A host never
/// throws — a call that the platform refuses to keep alive in the background
/// is still a working call while the app is on screen, so a failure here is
/// reported and swallowed, not propagated into the join.
abstract class CallSessionHost {
  /// A call has started.
  Future<void> begin(CallSessionDescription description);

  /// The same call, described differently — the channel was renamed, or this
  /// client moved to another one.
  Future<void> update(CallSessionDescription description);

  /// The call is over.
  Future<void> end();
}

/// The host for platforms that keep a backgrounded app running on their own
/// (desktop), or that need only static configuration to do it (iOS).
class InactiveCallSessionHost implements CallSessionHost {
  const InactiveCallSessionHost();

  @override
  Future<void> begin(CallSessionDescription description) async {}

  @override
  Future<void> update(CallSessionDescription description) async {}

  @override
  Future<void> end() async {}
}

/// Android's foreground service, over the channel `MainActivity` answers.
class AndroidCallSessionHost implements CallSessionHost {
  const AndroidCallSessionHost();

  static const _channel = MethodChannel('raindrop/call_session');

  @override
  Future<void> begin(CallSessionDescription description) =>
      _send('begin', description);

  @override
  Future<void> update(CallSessionDescription description) =>
      _send('update', description);

  @override
  Future<void> end() async {
    try {
      await _channel.invokeMethod<void>('end');
    } on PlatformException {
      // Nothing to do about it: the notification outliving the call is
      // untidy, but the call itself has already ended.
    }
  }

  Future<void> _send(String method, CallSessionDescription description) async {
    try {
      await _channel.invokeMethod<void>(method, {
        'title': description.title,
        'body': description.body,
      });
    } on PlatformException {
      // The service could not be started — the notification permission is
      // denied, or the OS refused a background start. The call goes ahead
      // either way; it just will not survive leaving the app.
    }
  }
}

/// The host for the platform this build is running on. Swappable in tests and
/// by anything that wants a call announced differently.
CallSessionHost createCallSessionHost() => switch (currentPlatform) {
  RaindropPlatform.android => const AndroidCallSessionHost(),
  _ => const InactiveCallSessionHost(),
};
