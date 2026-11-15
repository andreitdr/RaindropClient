import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/widgets/adaptive.dart';
import '../../voice/controllers/voice_call_controller.dart';
import '../controllers/servers_controller.dart';
import '../controllers/session_controller.dart';

/// Removes [server] from this device, after asking. The one place this is
/// done from, so the rail's menu, Settings, and the panes shown for a server
/// that is down or will not sign in all say and do the same thing.
///
/// It is local and needs nothing from the server, so it works when the
/// server is unreachable or gone. The account is not deleted: it stays on the
/// server, where nobody can sign in to it but this person — from one of
/// their paired devices, or with their recovery words — and adding the server
/// again arrives back at it.
Future<void> confirmRemoveServer(
  BuildContext context,
  WidgetRef ref,
  ServerProfile server,
) async {
  final confirmed = await showAdaptiveConfirm(
    context,
    title: 'Remove ${server.displayName}?',
    message:
        'This takes the server off this device, along with the messages '
        'stored here for it. Your account stays on the server: only your '
        'paired devices or your recovery words can sign back in to it, and '
        'you can add the server again at any time.',
    confirmLabel: 'Remove',
    destructive: true,
  );
  if (!confirmed) return;

  final call = ref.read(voiceCallProvider.notifier);
  if (ref.read(voiceCallProvider).serverId == server.id) await call.leave();

  // Tells the server, if it is listening, to forget this device — then
  // carries on without waiting for an answer.
  await ref
      .read(serverSessionProvider(server.id).notifier)
      .logout(forgetDevice: true);
  await ref.read(serversControllerProvider.notifier).remove(server.id);
}
