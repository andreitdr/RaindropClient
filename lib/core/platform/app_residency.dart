/// Whether the app stays running when its window is closed, on the desktops.
///
/// A phone decides for itself what runs in the background; a desktop app
/// decides by what its close button does. With residency on, closing the
/// window only hides it: the app stays signed in, online and in any call, and
/// an icon — the menu bar on a Mac, the notification area on Windows, the
/// tray on Linux — is the way back to it and the way to quit.
///
/// **Quitting is never done here.** Every way out — the icon's Quit, Cmd+Q,
/// logging off, or closing the window with residency off — goes through
/// Flutter's exit request, where the call controller leaves the call first
/// (`VoiceCallController.leaveNow`). So the rule for ending a call on the way
/// out lives in one place, whatever the platform.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_info.dart';

/// Something the app's icon asked for that only the app can do. Showing the
/// window and quitting are not here: the icon does those itself.
enum ResidencyCommand {
  /// Open Device settings — the icon's **Settings…**.
  openSettings;

  /// The command [name] stands for, or null for one this build has never
  /// heard of.
  static ResidencyCommand? named(Object? name) =>
      values.where((command) => command.name == name).firstOrNull;
}

/// The desktop's window and its icon, as far as staying running goes.
abstract class AppResidency {
  /// Whether this platform can keep the app running with its window closed.
  /// Where it cannot, Settings does not offer the choice.
  bool get available;

  /// Applies the person's choice: true makes closing the window hide it,
  /// false makes it quit. Safe to call any number of times.
  Future<void> setKeepRunningWhenClosed(bool keep);

  /// What the icon asked the app to do.
  Stream<ResidencyCommand> get commands;
}

/// The residency for platforms where closing a window is the OS's business,
/// not the app's: the phones.
class NoAppResidency implements AppResidency {
  const NoAppResidency();

  @override
  bool get available => false;

  @override
  Future<void> setKeepRunningWhenClosed(bool keep) async {}

  @override
  Stream<ResidencyCommand> get commands => const Stream.empty();
}

/// The desktops', over the channel each runner's shell answers
/// (`macos/Runner/RaindropShell.swift`, `windows/runner/raindrop_shell.cpp`,
/// `linux/runner/raindrop_shell.cc`).
///
/// Closing the window hides it, and an icon brings it back: the menu bar item
/// on a Mac (whose Dock icon stays too), the notification-area icon on
/// Windows, the tray on Linux. Its menu carries the call's controls while a
/// call is up. A Linux desktop with no tray — GNOME without its AppIndicator
/// extension — gets the window minimised instead, so there is always a way
/// back to it.
class DesktopAppResidency implements AppResidency {
  const DesktopAppResidency();

  static const _channel = MethodChannel('raindrop/residency');

  /// What the icon asks for. One listener for the process, set the
  /// first time anybody asks, as the call session's channel does.
  static final _commands = StreamController<ResidencyCommand>.broadcast();
  static bool _listening = false;

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'command') return;
      final command = ResidencyCommand.named(call.arguments);
      if (command != null) _commands.add(command);
    });
  }

  @override
  bool get available => true;

  @override
  Future<void> setKeepRunningWhenClosed(bool keep) async {
    _listen();
    try {
      await _channel.invokeMethod<void>('setKeepRunning', {'keep': keep});
    } on PlatformException {
      // The window keeps whatever it did before; nothing worse.
    } on MissingPluginException {
      // A build without the platform side: closing quits, as it always did.
    }
  }

  @override
  Stream<ResidencyCommand> get commands {
    _listen();
    return _commands.stream;
  }
}

/// The residency for the platform this build is running on: the desktops',
/// and none on a phone.
AppResidency createAppResidency() =>
    isDesktopPlatform ? const DesktopAppResidency() : const NoAppResidency();

/// The residency the app uses. Overridden in tests.
final appResidencyProvider = Provider<AppResidency>(
  (_) => createAppResidency(),
);
