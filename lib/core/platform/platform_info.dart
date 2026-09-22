import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

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
