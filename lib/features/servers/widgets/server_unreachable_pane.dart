import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/adaptive.dart';
import '../controllers/session_controller.dart';
import 'remove_server.dart';

/// Shown in the chat pane, beside the server rail, when restoring the session
/// for [profile] failed without the server saying anything about it: the
/// server did not answer, or something else went wrong on the way. The stored
/// token is untouched, so a retry that gets through signs straight back in —
/// unlike `SignInPane`, which is for a server that answered and refused.
///
/// It names the address, because an address that has gone stale (a home
/// server whose IP changed) looks exactly like a server that is down.
class ServerUnreachablePane extends ConsumerWidget {
  const ServerUnreachablePane({
    super.key,
    required this.profile,
    required this.error,
  });

  final ServerProfile profile;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retrying = ref.watch(serverSessionProvider(profile.id)).isLoading;
    final theme = Theme.of(context);
    final network =
        error is ApiException && (error as ApiException).isNetworkError;
    final address = '${profile.host}:${profile.port}';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    network
                        ? "Can't reach ${profile.displayName}"
                        : 'Could not connect to ${profile.displayName}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    network
                        ? 'Nothing answered at $address. Check your '
                              'connection, that the server is running, and '
                              'that its address has not changed.'
                        : '$error',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: retrying
                        ? null
                        : () =>
                              ref.invalidate(serverSessionProvider(profile.id)),
                    child: retrying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: AdaptiveActivityIndicator(size: 18),
                          )
                        : const Text('Try again'),
                  ),
                  const SizedBox(height: 8),
                  // A server that is gone for good never answers, so taking
                  // it off this device cannot depend on it answering.
                  TextButton(
                    onPressed: () => confirmRemoveServer(context, ref, profile),
                    child: const Text('Remove from this device'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
