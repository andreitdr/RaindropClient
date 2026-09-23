import 'dart:io';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/crypto/crypto_store.dart';
import 'core/layout/layout_controller.dart';
import 'core/layout/layout_store.dart';
import 'core/network/pin_registry.dart';
import 'core/storage/app_prefs.dart';
import 'core/storage/attachment_cache.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_definition.dart';
import 'features/home/layout/main_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Before anything opens a connection: voice's own sockets only trust a
  // self-signed server through this — see PinRegistry.
  HttpOverrides.global = PinnedHttpOverrides();

  // The end-to-end encryption core is a Rust library (../RaindropCrypto),
  // built and linked by native/raindrop_crypto_builder.
  await CryptoStores.initialize();

  // Plays video and audio attachments on every platform the app targets.
  MediaKit.ensureInitialized();

  // Decrypted attachments live only as long as the run that opened them:
  // emptied now (in case the last run was killed) and again on the way out.
  final attachments = await AttachmentCache.instance();
  _exitListener = AppLifecycleListener(
    onExitRequested: () async {
      await attachments.clearPlaintext();
      return AppExitResponse.exit;
    },
    onDetach: () => attachments.clearPlaintext(),
  );

  final prefs = AppPrefs(await SharedPreferences.getInstance());
  final builtInThemes = await loadBuiltInThemes();
  final layoutStore = await LayoutStore.open();
  final savedLayout = await layoutStore.load();

  runApp(
    ProviderScope(
      overrides: [
        appPrefsProvider.overrideWithValue(prefs),
        builtInThemesProvider.overrideWithValue(builtInThemes),
        layoutStoreProvider.overrideWithValue(layoutStore),
        initialLayoutProvider.overrideWithValue(savedLayout),
        layoutRulesProvider.overrideWithValue(mainLayoutRules),
      ],
      child: const RaindropApp(),
    ),
  );
}

/// Held so it is not collected: it clears decrypted attachments on exit.
// ignore: unused_element
AppLifecycleListener? _exitListener;
