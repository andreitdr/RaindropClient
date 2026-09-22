import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/server_profile.dart';
import '../../../core/widgets/adaptive.dart';
import '../../channels/controllers/channels_controller.dart';
import '../../channels/controllers/selected_channel_controller.dart';
import '../../channels/models/channel.dart';
import '../../channels/widgets/channel_sidebar.dart';
import '../../chat/widgets/chat_view.dart';
import '../../security/controllers/device_setup_controller.dart';
import '../../security/widgets/encryption_setup_pane.dart';
import '../../security/widgets/recovery_words_dialog.dart';
import '../../members/widgets/member_list.dart';
import '../../onboarding/screens/connect_server_screen.dart';
import '../../onboarding/screens/reauth_prompt.dart';
import '../../servers/controllers/servers_controller.dart';
import '../../servers/controllers/session_controller.dart';
import '../../servers/widgets/server_rail.dart';
import '../../voice/controllers/voice_call_controller.dart';
import '../../voice/widgets/voice_channel_view.dart';
import '../../voice/widgets/voice_controls.dart';

/// The app's main window once at least one server is connected: a
/// responsive three/four-pane layout (server rail, channel list, chat,
/// optional member list) that collapses to a single pane with a drawer on
/// narrow/mobile widths — the same shape most chat clients converge on.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serversControllerProvider);
    if (servers.isEmpty) return const ConnectServerScreen();

    final activeId = ref.watch(activeServerIdProvider) ?? servers.first.id;
    final sessionAsync = ref.watch(serverSessionProvider(activeId));

    return sessionAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: AdaptiveActivityIndicator())),
      error: (err, _) =>
          Scaffold(body: Center(child: Text('Could not connect: $err'))),
      data: (session) {
        if (session == null) {
          final profile = servers.firstWhere(
            (s) => s.id == activeId,
            orElse: () => servers.first,
          );
          return _SignedOutLayout(profile: profile);
        }
        return _ShellLayout(session: session);
      },
    );
  }
}

/// The shell as it looks with no valid session for the active server: the
/// server rail stays in place so the app always opens on its usual layout,
/// and the login form takes the chat pane.
class _SignedOutLayout extends StatelessWidget {
  const _SignedOutLayout({required this.profile});

  final ServerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          ServerRail(activeServerId: profile.id),
          Expanded(child: ReauthPrompt(profile: profile)),
        ],
      ),
    );
  }
}

class _ShellLayout extends ConsumerStatefulWidget {
  const _ShellLayout({required this.session});

  final ServerSession session;

  @override
  ConsumerState<_ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<_ShellLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showMembers = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final serverId = session.profile.id;
    final channels = ref.watch(channelsProvider(serverId)).valueOrNull;
    // The stored selection is only ever a user's *choice* — it can point at
    // another server's channel, or one that has since been deleted — so the
    // channel to render is resolved against what this server actually has.
    final channel = resolveChannel(
      channels ?? const [],
      ref.watch(selectedChannelIdProvider),
    );

    // This device's encryption setup. While it cannot take part yet, the
    // setup pane takes the chat pane; a fresh recovery key is shown once.
    final setup = ref.watch(deviceSetupProvider(serverId)).valueOrNull;
    ref.listen(deviceSetupProvider(serverId), (_, next) {
      final state = next.valueOrNull;
      if (state is! DeviceSetupReady || state.recoveryWords == null) return;
      ref
          .read(deviceSetupProvider(serverId).notifier)
          .acknowledgeRecoveryWords();
      showRecoveryWordsDialog(context, state.recoveryWords!);
    });

    // A call that ended without this client hanging up says why, once.
    ref.listen(voiceCallProvider.select((call) => call.notice), (_, notice) {
      if (notice == null) return;
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(notice)));
      ref.read(voiceCallProvider.notifier).dismissNotice();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isNarrow = width < 680;
        final canShowMembers = width >= 1000;

        final menuButton = isNarrow
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null;

        final trailingActions = (canShowMembers || isNarrow)
            ? <Widget>[]
            : [
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  tooltip: 'Members',
                  onPressed: () => setState(() => _showMembers = !_showMembers),
                ),
              ];

        final Widget channelPane = switch (channel) {
          null => _NoChannelSelected(
            loading: channels == null,
            leading: menuButton,
          ),
          Channel(type: ChannelType.voice) => VoiceChannelView(
            serverId: serverId,
            channel: channel,
            leading: menuButton,
            trailingActions: trailingActions,
          ),
          _ => ChatView(
            serverId: serverId,
            channel: channel,
            leading: menuButton,
            trailingActions: trailingActions,
          ),
        };

        final Widget chat = switch (setup) {
          DeviceSetupNeedsKeys() ||
          DeviceSetupLinking() ||
          DeviceSetupReplaced() => EncryptionSetupPane(
            serverId: serverId,
            state: setup!,
            leading: menuButton,
          ),
          _ => channelPane,
        };

        if (isNarrow) {
          return Scaffold(
            key: _scaffoldKey,
            drawer: Drawer(
              width: 76 + 240,
              child: Row(
                children: [
                  ServerRail(activeServerId: session.profile.id),
                  ChannelSidebar(
                    server: session.profile,
                    currentUser: session.currentUser,
                  ),
                ],
              ),
            ),
            // The sidebar — and the call controls in it — lives in the
            // drawer here, so a call in progress gets a bar of its own.
            body: SafeArea(
              child: Column(
                children: [
                  const VoiceConnectionBar(compact: true),
                  Expanded(child: chat),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              ServerRail(activeServerId: session.profile.id),
              ChannelSidebar(
                server: session.profile,
                currentUser: session.currentUser,
              ),
              Expanded(child: chat),
              if (canShowMembers || _showMembers)
                MemberList(
                  serverId: serverId,
                  currentUserId: session.currentUser.userId,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// What the chat pane shows before there is a channel to show: the server's
/// channel list is still loading, or it came back empty.
class _NoChannelSelected extends StatelessWidget {
  const _NoChannelSelected({required this.loading, this.leading});

  final bool loading;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SafeArea(
          bottom: false,
          left: false,
          right: false,
          child: SizedBox(height: 52, child: Row(children: [?leading])),
        ),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: loading
                ? const AdaptiveActivityIndicator()
                : Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'There are no channels on this server yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
