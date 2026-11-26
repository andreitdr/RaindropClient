import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_shell.dart';
import '../../features/onboarding/screens/connect_server_screen.dart';
import '../../features/onboarding/screens/server_auth_screen.dart';
import '../../features/roles/screens/role_editor_screen.dart';
import '../../features/roles/screens/roles_screen.dart';
import '../../features/settings/screens/device_settings_screen.dart';
import '../../features/settings/screens/identity_settings_screen.dart';
import '../../features/settings/screens/layout_editor_screen.dart';
import '../../features/settings/screens/server_settings_screen.dart';
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
      builder: (context, state) => const DeviceSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/identity',
      builder: (context, state) => const IdentitySettingsScreen(),
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
    GoRoute(
      path: '/servers/:serverId/settings',
      builder: (context, state) =>
          ServerSettingsScreen(serverId: state.pathParameters['serverId']!),
    ),
    GoRoute(
      path: '/servers/:serverId/roles',
      builder: (context, state) =>
          RolesScreen(serverId: state.pathParameters['serverId']!),
    ),
    GoRoute(
      path: '/servers/:serverId/roles/new',
      builder: (context, state) =>
          RoleEditorScreen(serverId: state.pathParameters['serverId']!),
    ),
    GoRoute(
      path: '/servers/:serverId/roles/:roleId',
      builder: (context, state) => RoleEditorScreen(
        serverId: state.pathParameters['serverId']!,
        roleId: state.pathParameters['roleId'],
      ),
    ),
  ],
);
