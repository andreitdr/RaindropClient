import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/pin_registry.dart';
import 'core/storage/app_prefs.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_definition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Before anything opens a connection: voice's own sockets only trust a
  // self-signed server through this — see PinRegistry.
  HttpOverrides.global = PinnedHttpOverrides();

  final prefs = AppPrefs(await SharedPreferences.getInstance());
  final builtInThemes = await loadBuiltInThemes();

  runApp(
    ProviderScope(
      overrides: [
        appPrefsProvider.overrideWithValue(prefs),
        builtInThemesProvider.overrideWithValue(builtInThemes),
      ],
      child: const RaindropApp(),
    ),
  );
}
