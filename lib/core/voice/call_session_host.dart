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
///   A desktop's host still has something to do: it shows the call — the
///   notch or the menu bar, the notification area, the tray
///   ([DesktopCallSessionHost]).
///
/// It is also how the call is *shown* outside the app — the notch or the menu
/// bar on a Mac, the Dynamic Island and the Lock Screen on an iPhone, the
/// ongoing notification (and a Live Update, where there is one) on Android,
/// the tray on Windows and Linux — and how that surface's controls (mute,
/// deafen, leave) come back. So the description is the whole call as a glance
/// shows it, sent again whenever any of it changes, and [CallSessionHost.actions]
/// is what the person pressed out there.
///
/// [CallSessionHost] is the seam between those: the call controller begins a
/// session when a call starts, updates it whenever what it shows changes, and
/// ends it when the call does — not while a dropped call is being rejoined,
/// which is still the same call. A platform with nothing to do gets
/// [InactiveCallSessionHost], not a branch at the call site.
library;

import 'dart:async';

import 'package:flutter/services.dart';

import '../platform/platform_info.dart';

/// What the OS shows about the call it is being asked to keep alive. Android
/// puts these in the ongoing notification, iOS in the Live Activity, a Mac in
/// the notch or the menu bar; a host that shows nothing ignores them.
///
/// Compared by value, so the call controller can send it again only when
/// something on it has actually changed. Nothing here ticks: the timer is
/// [connectedAt], and every surface draws its own clock from it.
class CallSessionDescription {
  const CallSessionDescription({
    required this.title,
    required this.body,
    this.connectedAt,
    this.micOn = true,
    this.deafened = false,
    this.reconnecting = false,
    this.participants = 0,
    this.sharingScreen = false,
    this.encrypted = false,
    this.concealed = false,
    this.showOutsideApp = true,
  });

  /// The call, in a few words — the channel being talked in.
  final String title;

  /// Where that channel is: the server's name.
  final String body;

  /// When this call first connected, or null before it has. A dropped call
  /// that was picked back up keeps the time it began, so its timer does not
  /// start again from nothing.
  final DateTime? connectedAt;

  /// Whether anybody can hear this member: the microphone is on, and no
  /// moderator, missing permission or failed device is keeping it silent.
  final bool micOn;

  /// This member hears nobody.
  final bool deafened;

  /// The connection dropped and the call is being put back together.
  final bool reconnecting;

  /// How many members are in the call, this one included. 0 while the
  /// roster has not been read yet.
  final int participants;

  /// This member is sharing their screen.
  final bool sharingScreen;

  /// The call's media is end-to-end encrypted.
  final bool encrypted;

  /// The app is locked, so [title] and [body] are already the generic words
  /// and the surface should name nothing else either — not the channel, the
  /// server or anybody in the call.
  final bool concealed;

  /// The person wants the call shown prominently outside the app — the
  /// Dynamic Island and the Lock Screen, Android's Live Update chip and the
  /// Now Bar. A platform that has to show *something* for a call to keep
  /// running (Android's ongoing notification) still does, just not promoted.
  final bool showOutsideApp;

  /// The description as a platform channel carries it.
  Map<String, Object?> toMap() => {
    'title': title,
    'body': body,
    'connectedAt': connectedAt?.millisecondsSinceEpoch,
    'micOn': micOn,
    'deafened': deafened,
    'reconnecting': reconnecting,
    'participants': participants,
    'sharingScreen': sharingScreen,
    'encrypted': encrypted,
    'concealed': concealed,
    'showOutsideApp': showOutsideApp,
  };

  @override
  bool operator ==(Object other) =>
      other is CallSessionDescription &&
      other.title == title &&
      other.body == body &&
      other.connectedAt == connectedAt &&
      other.micOn == micOn &&
      other.deafened == deafened &&
      other.reconnecting == reconnecting &&
      other.participants == participants &&
      other.sharingScreen == sharingScreen &&
      other.encrypted == encrypted &&
      other.concealed == concealed &&
      other.showOutsideApp == showOutsideApp;

  @override
  int get hashCode => Object.hash(
    title,
    body,
    connectedAt,
    micOn,
    deafened,
    reconnecting,
    participants,
    sharingScreen,
    encrypted,
    concealed,
    showOutsideApp,
  );
}

/// A control the person pressed on the call's surface outside the app.
///
/// The names are what the platform sends ([CallSessionAction.name]), so a
/// native side and this enum cannot drift apart silently: a name this build
/// does not know is ignored.
enum CallSessionAction {
  /// Flip the microphone, as the call bar's mute button does.
  toggleMute,

  /// Flip deafen, as the call bar's headset button does.
  toggleDeafen,

  /// Hang up.
  leave;

  /// The action [name] stands for, or null for one this build has never
  /// heard of.
  static CallSessionAction? named(Object? name) =>
      values.where((action) => action.name == name).firstOrNull;
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

  /// The same call, described differently — muted, a member joined, the
  /// channel was renamed, the connection is being rebuilt.
  Future<void> update(CallSessionDescription description);

  /// The call is over.
  Future<void> end();

  /// The call is about to start capturing the screen, or has stopped.
  ///
  /// Android will not hand an app the screen unless a foreground service that
  /// says it is for *media projection* is already running — and will not let
  /// that service start until the user has agreed to the capture. So this
  /// comes after the consent and before the capture, and the service a call
  /// already has is told to say so too. The notification changes with it, and
  /// gains a way to stop sharing without coming back to the app.
  ///
  /// Answers whether the capture may go ahead. A platform with nothing to
  /// arrange says yes; Android says no when the service could not take the
  /// type, since a capture started anyway would be refused by the system.
  Future<bool> setScreenCapture(bool capturing);

  /// Fires when the capture was ended from outside the app: the notification's
  /// **Stop sharing**, or the system closing the capture itself (its own stop
  /// control, or the screen locking). The media library reports neither, so
  /// without this a share would go on being announced with nothing behind it.
  Stream<void> get screenCaptureEnded;

  /// What the person pressed on the call's surface outside the app. The
  /// controller applies each the way the matching in-app button would.
  Stream<CallSessionAction> get actions;

  /// Whether this host shows the call somewhere the person may choose to do
  /// without ([CallSessionDescription.showOutsideApp]) — which is what puts
  /// the choice in Settings. False where nothing is shown, and where what is
  /// shown is the price of the call running at all.
  bool get showsCallOutsideApp;
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

  @override
  Future<bool> setScreenCapture(bool capturing) async => true;

  @override
  Stream<void> get screenCaptureEnded => const Stream.empty();

  @override
  Stream<CallSessionAction> get actions => const Stream.empty();

  @override
  bool get showsCallOutsideApp => false;
}

/// A host whose platform side answers over `raindrop/call_session`: Android's
/// foreground service (`MainActivity`), and each desktop runner's shell
/// ([DesktopCallSessionHost]). The messages are the same on both —
/// `begin`/`update` with [CallSessionDescription.toMap], `end`, and `action`
/// coming back — so only what differs is in the subclasses.
abstract class ChannelCallSessionHost implements CallSessionHost {
  const ChannelCallSessionHost();

  static const _channel = MethodChannel('raindrop/call_session');

  /// What the platform says back. One listener for the process, set the first
  /// time anybody asks: the channel has a single handler, and hosts are
  /// `const` and interchangeable.
  static final _captureEnded = StreamController<void>.broadcast();
  static final _actions = StreamController<CallSessionAction>.broadcast();
  static bool _listening = false;

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'captureEnded':
          _captureEnded.add(null);
        case 'action':
          final action = CallSessionAction.named(call.arguments);
          if (action != null) _actions.add(action);
      }
    });
  }

  @override
  Stream<void> get screenCaptureEnded {
    _listen();
    return _captureEnded.stream;
  }

  @override
  Stream<CallSessionAction> get actions {
    _listen();
    return _actions.stream;
  }

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
      // Nothing to do about it: the surface outliving the call is untidy,
      // but the call itself has already ended.
    } on MissingPluginException {
      // A build without the platform side: there was nothing to end.
    }
  }

  Future<void> _send(String method, CallSessionDescription description) async {
    _listen();
    try {
      await _channel.invokeMethod<void>(method, description.toMap());
    } on PlatformException {
      // The platform could not show or keep the call — on Android the
      // notification permission is denied, or the OS refused a background
      // start. The call goes ahead either way.
    } on MissingPluginException {
      // A build without the platform side: the call just is not shown.
    }
  }
}

/// Android's foreground service, over the channel `MainActivity` answers.
class AndroidCallSessionHost extends ChannelCallSessionHost {
  const AndroidCallSessionHost();

  /// Not yet: the ongoing notification is what keeps the call running, so it
  /// is not the person's to turn off. Promoting it — the status bar chip, the
  /// Now Bar — will be.
  @override
  bool get showsCallOutsideApp => false;

  @override
  Future<bool> setScreenCapture(bool capturing) async {
    ChannelCallSessionHost._listen();
    try {
      return await ChannelCallSessionHost._channel.invokeMethod<bool>(
            'capture',
            {'capturing': capturing},
          ) ??
          false;
    } on PlatformException {
      // The service is not running (no call), or the system refused it the
      // type — which it does when the user has not agreed to a capture.
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// The desktops' call surface, over the channel each runner's shell answers:
/// the Mac's notch, or its menu bar where there is no notch
/// (`macos/Runner/RaindropShell.swift`); the notification-area icon on Windows
/// (`windows/runner/raindrop_shell.cpp`); the tray on Linux
/// (`linux/runner/raindrop_shell.cc`).
///
/// A desktop keeps a call running whatever its window does, so this is only
/// about showing it — always, for as long as the call lasts. Nothing about it
/// is the person's to turn off: it is the call they are in, shown where they
/// can see it, the way a phone's call shows in its status bar.
class DesktopCallSessionHost extends ChannelCallSessionHost {
  const DesktopCallSessionHost();

  @override
  bool get showsCallOutsideApp => false;

  /// A desktop asks nothing of the app before a capture; the Mac's Screen
  /// Recording permission is the system's own, asked by the share picker.
  @override
  Future<bool> setScreenCapture(bool capturing) async => true;
}

/// The host for the platform this build is running on. Swappable in tests and
/// by anything that wants a call announced differently.
CallSessionHost createCallSessionHost() => switch (currentPlatform) {
  RaindropPlatform.android => const AndroidCallSessionHost(),
  RaindropPlatform.macos ||
  RaindropPlatform.windows ||
  RaindropPlatform.linux => const DesktopCallSessionHost(),
  _ => const InactiveCallSessionHost(),
};
