/// What Raindrop does when it is not the window in front: whether closing its
/// window keeps it running, and whether a call is shown outside the app.
///
/// Both are this device's own, like the rest of Device settings, and both are
/// on until the person turns them off.
class BackgroundSettings {
  const BackgroundSettings({
    this.keepRunningWhenClosed = true,
    this.showCallOutsideApp = true,
  });

  /// Desktop only: closing the window hides it rather than quitting, and the
  /// app stays in the menu bar or the tray — signed in, online, and still in
  /// any call — until it is quit from there. Off, closing the window quits,
  /// and quitting leaves the call.
  final bool keepRunningWhenClosed;

  /// Phones only: a call is shown prominently outside the app — the Dynamic
  /// Island and the Lock Screen on an iPhone, the status bar chip and the
  /// Now Bar on Android. Off, Android still shows its ongoing notification,
  /// which a call needs to keep running in the background.
  final bool showCallOutsideApp;

  BackgroundSettings copyWith({
    bool? keepRunningWhenClosed,
    bool? showCallOutsideApp,
  }) => BackgroundSettings(
    keepRunningWhenClosed: keepRunningWhenClosed ?? this.keepRunningWhenClosed,
    showCallOutsideApp: showCallOutsideApp ?? this.showCallOutsideApp,
  );

  /// Reads what [toJson] wrote. Anything missing or of the wrong type is the
  /// default, so a setting added later starts on for everybody.
  factory BackgroundSettings.fromJson(Map<String, dynamic> json) {
    const defaults = BackgroundSettings();
    bool read(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    return BackgroundSettings(
      keepRunningWhenClosed: read(
        'keepRunningWhenClosed',
        defaults.keepRunningWhenClosed,
      ),
      showCallOutsideApp: read(
        'showCallOutsideApp',
        defaults.showCallOutsideApp,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'keepRunningWhenClosed': keepRunningWhenClosed,
    'showCallOutsideApp': showCallOutsideApp,
  };

  @override
  bool operator ==(Object other) =>
      other is BackgroundSettings &&
      other.keepRunningWhenClosed == keepRunningWhenClosed &&
      other.showCallOutsideApp == showCallOutsideApp;

  @override
  int get hashCode => Object.hash(keepRunningWhenClosed, showCallOutsideApp);
}
