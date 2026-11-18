import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app bar of a settings page. Opened the usual way, a page sits on top
/// of the main view and the app bar's own back arrow returns to it. A page
/// that is the only one on the stack — reached by `go` rather than `push`,
/// or restored on its own — would have no way out, so it gets a close button
/// that goes back to the main view instead.
AppBar settingsAppBar(BuildContext context, {required Widget title}) {
  return AppBar(
    title: title,
    leading: context.canPop()
        ? null
        : IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => context.go('/'),
          ),
  );
}
