import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'windows_processes.dart' as windows;

/// Central place for platform branching so feature code never calls
/// `Platform.isX` or `defaultTargetPlatform` directly. Keeping every check
/// here means a new target (say, web) only needs updating in one file.
enum RaindropPlatform { ios, macos, android, windows, linux, web }

RaindropPlatform get currentPlatform {
  if (kIsWeb) return RaindropPlatform.web;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return RaindropPlatform.ios;
    case TargetPlatform.macOS:
      return RaindropPlatform.macos;
    case TargetPlatform.android:
      return RaindropPlatform.android;
    case TargetPlatform.windows:
      return RaindropPlatform.windows;
    case TargetPlatform.linux:
      return RaindropPlatform.linux;
    default:
      return RaindropPlatform.linux;
  }
}

/// Apple platforms get Cupertino-flavored chrome (nav bars, action sheets,
/// switches) because that is what "native feel" means on iOS and macOS.
bool get isApplePlatform =>
    currentPlatform == RaindropPlatform.ios ||
    currentPlatform == RaindropPlatform.macos;

bool get isDesktopPlatform =>
    currentPlatform == RaindropPlatform.macos ||
    currentPlatform == RaindropPlatform.windows ||
    currentPlatform == RaindropPlatform.linux;

bool get isMobilePlatform =>
    currentPlatform == RaindropPlatform.ios ||
    currentPlatform == RaindropPlatform.android;

/// Whether the app can pick which microphone and speakers a call uses. On
/// phones the OS routes audio (earpiece, speaker, headset) itself, and the
/// voice library cannot choose a device there.
bool get canChooseAudioDevices => isDesktopPlatform;

/// Whether the app can pick which camera a call uses. True everywhere, unlike
/// [canChooseAudioDevices]: on a phone the front and back cameras are two
/// devices and choosing between them is the whole point, where audio routing is
/// the OS's business.
bool get canChooseCamera => true;

/// Whether this platform has somewhere to put a frame processor.
///
/// The camera itself works everywhere; the effects need a hook into the capture
/// pipeline, and the media library only has one on these three — on Windows and
/// Linux there is no chain between the capturer and the source to insert
/// anything into. Whether effects can *actually* run also depends on the build
/// carrying a segmentation model, which is `cameraEffectsAvailable` in
/// `core/video/camera_effects_engine.dart`; that is what the UI reads.
bool get canUseCameraEffects =>
    currentPlatform == RaindropPlatform.macos ||
    currentPlatform == RaindropPlatform.ios ||
    currentPlatform == RaindropPlatform.android;

/// Whether this platform can share its screen into a call. The desktops only:
/// on a phone, showing another app sends Raindrop to the background, and
/// until calls keep running there a share would stop the moment it started.
bool get canShareScreen => isDesktopPlatform;

/// Whether the system has to be asked before the screen can be recorded — the
/// Screen Recording permission on macOS. Elsewhere sharing just works, or the
/// system puts up its own picker.
bool get needsScreenCapturePermission =>
    currentPlatform == RaindropPlatform.macos;

/// The first Windows build whose audio engine can capture one process tree's
/// sound on its own (WASAPI process loopback): Windows Server 2022, and so
/// every Windows 11. Older builds have no way to separate one app's sound
/// from everything else's.
const processLoopbackMinimumBuild = 20348;

/// The build number in a Windows version string, as
/// `Platform.operatingSystemVersion` gives it (`"Windows 10 Pro" 10.0 (Build
/// 22631)`), or null when it names none.
int? windowsBuildOf(String version) {
  final match = RegExp(r'Build (\d+)').firstMatch(version);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Why the sound of window [windowId] cannot be shared from this machine, or
/// null when it can — which is only ever on Windows 11.
///
/// macOS has no way to send a window's sound as its own track without forking
/// its WebRTC build, and Linux's capture records everything Raindrop's own
/// call is playing too; both are on the roadmap rather than half-done here.
/// On Windows the capture takes the window's whole process tree, so a window
/// whose tree contains Raindrop is refused as well (see
/// `windows_processes.dart`).
String? windowAudioUnavailableReason(String windowId) {
  switch (currentPlatform) {
    case RaindropPlatform.windows:
      break;
    case RaindropPlatform.macos:
      return "Sharing a window's sound isn't available on macOS yet.";
    case RaindropPlatform.linux:
      return "Sharing a window's sound isn't available on Linux yet.";
    case RaindropPlatform.ios:
    case RaindropPlatform.android:
    case RaindropPlatform.web:
      return "Sharing a window's sound isn't available here.";
  }

  final build = windowsBuildOf(Platform.operatingSystemVersion);
  if (build == null || build < processLoopbackMinimumBuild) {
    return "Sharing a window's sound needs Windows 11.";
  }

  // flutter_webrtc names a window by its HWND, as a decimal string.
  final hwnd = int.tryParse(windowId);
  final owner = hwnd == null ? null : windows.windowProcessId(hwnd);
  if (owner == null) return 'That window has closed.';

  return windows.windowAudioRefusal(
    windowProcessId: owner,
    thisProcessId: windows.thisProcessId,
    thisProcessAncestors: windows.thisProcessAncestors(),
  );
}

/// Whether window [windowId] is one of Raindrop's own, so the share picker can
/// leave it out. Only answerable on Windows; elsewhere sharing Raindrop itself
/// is merely pointless, not harmful, since no sound comes with it.
bool isThisAppsWindow(String windowId) {
  if (currentPlatform != RaindropPlatform.windows) return false;
  final hwnd = int.tryParse(windowId);
  return hwnd != null && windows.windowProcessId(hwnd) == windows.thisProcessId;
}

/// Whether window [windowId] is still open, checked just before sharing it.
/// On Windows a window that closed between choosing and sharing would have
/// its sound capture fall back to everything else's; elsewhere the share
/// itself fails and says so.
bool isWindowStillOpen(String windowId) {
  if (currentPlatform != RaindropPlatform.windows) return true;
  final hwnd = int.tryParse(windowId);
  return hwnd != null && windows.windowExists(hwnd);
}
/// Whether a call can be moved between the earpiece and the loudspeaker.
/// Only phones have both; on desktop the output device picker
/// ([canChooseAudioDevices]) is the equivalent, and the two are deliberately
/// never offered together.
bool get canUseSpeakerphone => isMobilePlatform;

/// Whether the camera can scan a QR code here — the device-link code another
/// device shows. `mobile_scanner` covers iOS, Android and macOS; elsewhere
/// the code is typed or pasted instead.
bool get canScanCodes =>
    currentPlatform == RaindropPlatform.ios ||
    currentPlatform == RaindropPlatform.android ||
    currentPlatform == RaindropPlatform.macos;

/// Not used at import time on web, guarded so this file stays import-safe.
bool get isRunningOnWeb => kIsWeb;

String get operatingSystemName => kIsWeb ? 'web' : Platform.operatingSystem;
