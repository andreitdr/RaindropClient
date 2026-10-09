// The ids the main view's layout file uses. They are written to disk, so a
// rename orphans users' saved layouts: add new ids, don't change these.

/// The main view's panes, left to right by default.
abstract final class MainPanes {
  static const servers = 'servers';
  static const channels = 'channels';
  static const content = 'content';
  static const members = 'members';
}

/// The toolbars inside the panes that buttons can be placed in.
abstract final class MainSlots {
  /// Under the server list in the rail.
  static const railFooter = 'rail.footer';

  /// Beside the signed-in user at the foot of the channel sidebar.
  static const userPanel = 'user.trailing';

  /// The right end of the chat (or voice) pane's top bar.
  static const topBar = 'topBar.trailing';
}

abstract final class MainButtons {
  static const addServer = 'server.add';
  static const settings = 'app.settings';
  static const mute = 'voice.mute';
  static const deafen = 'voice.deafen';
  static const camera = 'voice.camera';
  static const members = 'members.toggle';
}
