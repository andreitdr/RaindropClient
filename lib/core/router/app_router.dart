import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_shell.dart';
import '../../features/onboarding/screens/connect_server_screen.dart';
import '../../features/onboarding/screens/server_auth_screen.dart';
import '../../features/settings/screens/layout_editor_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/theme_editor_screen.dart';
import '../theme/theme_definition.dart';

/// Routes are intentionally shallow: `/` decides for itself whether to show
/// onboarding or the shell (see [HomeShell]), so nothing here needs a
/// redirect guard. `/connect/auth` carries its handoff via `extra` rather
/// than the URL, since [ConnectServerFlow] holds a live [ApiClient] that
/// can't round-trip through a query string.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeShell()),
    GoRoute(
      path: '/connect',
      builder: (context, state) => const ConnectServerScreen(),
    ),
    GoRoute(
      path: '/connect/auth',
      builder: (context, state) =>
          ServerAuthScreen(handoff: state.extra as ConnectHandoff),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/layout',
      builder: (context, state) => const LayoutEditorScreen(),
    ),
    GoRoute(
      path: '/settings/theme-editor',
      builder: (context, state) {
        final extra =
            state.extra
                as ({AppThemeDefinition starting, AppThemeDefinition? editing});
        return ThemeEditorScreen(
          starting: extra.starting,
          editing: extra.editing,
        );
      },
    ),
  ],
);
