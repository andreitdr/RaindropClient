import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_controller.dart';

class RaindropApp extends ConsumerWidget {
  const RaindropApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeThemeIdProvider);
    final catalog = ref.watch(themeCatalogProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final theme = resolveActiveTheme(
      activeId: activeId,
      catalog: catalog,
      platformBrightness: platformBrightness,
    );

    return MaterialApp.router(
      title: 'Raindrop',
      debugShowCheckedModeBanner: false,
      theme: theme.toThemeData(),
      routerConfig: appRouter,
    );
  }
}
