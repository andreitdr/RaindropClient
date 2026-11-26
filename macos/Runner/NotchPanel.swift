import Cocoa
import SwiftUI

/// Where a screen's camera housing is, and how much room the menu bar has
/// beside it — or nothing, for a screen without one.
///
/// AppKit has no "notch frame". What it has is the menu bar's height at the
/// housing (`safeAreaInsets.top`, non-zero only on a notched screen) and the
/// two usable strips either side of it (`auxiliaryTopLeftArea` and
/// `auxiliaryTopRightArea`); the notch is what lies between them.
struct NotchGeometry: Equatable {
  let screenFrame: NSRect
  let notchWidth: CGFloat
  let height: CGFloat

  static func of(_ screen: NSScreen) -> NotchGeometry? {
    let height = screen.safeAreaInsets.top
    guard height > 0,
      let left = screen.auxiliaryTopLeftArea,
      let right = screen.auxiliaryTopRightArea
    else { return nil }
    let notchWidth = screen.frame.width - left.width - right.width
    guard notchWidth > 0 else { return nil }
    return NotchGeometry(screenFrame: screen.frame, notchWidth: notchWidth, height: height)
  }

  /// Each side of the notch the compact island reaches into the menu bar.
  /// Narrow on purpose: whatever is under it — menu bar items crowding the
  /// notch — cannot be clicked while the island covers it.
  static let wing: CGFloat = 60

  var compactSize: NSSize {
    NSSize(width: notchWidth + 2 * NotchGeometry.wing, height: height)
  }

  var expandedSize: NSSize {
    NSSize(width: max(compactSize.width, 380), height: height + 86)
  }

  /// [size], hanging from the top of the screen at the notch's centre.
  func frame(for size: NSSize) -> NSRect {
    NSRect(
      x: screenFrame.midX - size.width / 2,
      y: screenFrame.maxY - size.height,
      width: size.width,
      height: size.height)
  }
}

/// What the island draws, and what its buttons do.
final class NotchModel: ObservableObject {
  @Published var call: CallDescription
  @Published var expanded = false
  let geometry: NotchGeometry
  let onAction: (CallAction) -> Void
  let onOpen: () -> Void

  init(
    call: CallDescription,
    geometry: NotchGeometry,
    onAction: @escaping (CallAction) -> Void,
    onOpen: @escaping () -> Void
  ) {
    self.call = call
    self.geometry = geometry
    self.onAction = onAction
    self.onOpen = onOpen
  }
}

/// The call, hanging from the notch: the microphone on the left, the timer on
/// the right, and on hover the call itself with its controls.
struct NotchView: View {
  @ObservedObject var model: NotchModel

  private var call: CallDescription { model.call }

  var body: some View {
    let size = model.expanded ? model.geometry.expandedSize : model.geometry.compactSize
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Image(systemName: call.microphoneSymbol)
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(call.micOn && !call.deafened ? .white : .red)
          .frame(width: NotchGeometry.wing)
        Spacer(minLength: 0)
        trailing
          .frame(width: NotchGeometry.wing)
      }
      .frame(height: model.geometry.height)

      if model.expanded {
        details
          .padding(.horizontal, 16)
          .padding(.bottom, 12)
          .transition(.opacity)
      }
    }
    .foregroundColor(.white)
    .frame(width: size.width, height: size.height, alignment: .top)
    .background(NotchShape(radius: model.expanded ? 22 : 10).fill(Color.black))
    // The island grows inside a panel already at its largest, so it hangs
    // from the top centre and the rest of the panel is clear.
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .animation(.easeOut(duration: 0.18), value: model.expanded)
  }

  @ViewBuilder private var trailing: some View {
    if call.reconnecting {
      Image(systemName: "arrow.triangle.2.circlepath")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.orange)
    } else if let connectedAt = call.connectedAt {
      // The system's own clock, so nothing has to tick to keep it current.
      Text(connectedAt, style: .timer)
        .font(.system(size: 12, weight: .medium))
        .monospacedDigit()
        .lineLimit(1)
    }
  }

  private var details: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: 8) {
        VStack(alignment: .leading, spacing: 2) {
          Text(call.reconnecting ? "Reconnecting…" : call.title)
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
          if !call.body.isEmpty {
            Text(call.body)
              .font(.system(size: 11))
              .foregroundColor(.gray)
              .lineLimit(1)
          }
        }
        Spacer(minLength: 8)
        if call.sharingScreen {
          Image(systemName: "rectangle.on.rectangle")
            .help("You are sharing your screen")
        }
        if call.encrypted {
          Image(systemName: "lock.fill")
            .help("End-to-end encrypted")
        }
        if call.participants > 0 {
          Label("\(call.participants)", systemImage: "person.2.fill")
            .font(.system(size: 11, weight: .medium))
            .help("\(call.participants) in the call")
        }
      }
      .font(.system(size: 11))

      HStack(spacing: 10) {
        NotchButton(
          symbol: call.micOn ? "mic.fill" : "mic.slash.fill",
          alarmed: !call.micOn,
          help: call.micOn ? "Mute" : "Unmute"
        ) { model.onAction(.toggleMute) }
        NotchButton(
          symbol: call.deafened ? "speaker.slash.fill" : "speaker.wave.2.fill",
          alarmed: call.deafened,
          help: call.deafened ? "Undeafen" : "Deafen"
        ) { model.onAction(.toggleDeafen) }
        NotchButton(symbol: "phone.down.fill", alarmed: true, help: "Leave call") {
          model.onAction(.leave)
        }
        Spacer(minLength: 0)
        NotchButton(symbol: "macwindow", alarmed: false, help: "Open Raindrop") {
          model.onOpen()
        }
      }
    }
  }
}

/// One round control in the expanded island.
struct NotchButton: View {
  let symbol: String
  let alarmed: Bool
  let help: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.white)
        .frame(width: 30, height: 30)
        .background(Circle().fill(alarmed ? Color.red : Color(white: 0.22)))
    }
    .buttonStyle(.plain)
    .help(help)
  }
}

/// The island's outline: square along the top, where it meets the edge of
/// the screen, and rounded along the bottom.
struct NotchShape: Shape {
  var radius: CGFloat

  var animatableData: CGFloat {
    get { radius }
    set { radius = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let r = min(radius, rect.height / 2, rect.width / 2)
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX - r, y: rect.maxY),
      control: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.minX, y: rect.maxY - r),
      control: CGPoint(x: rect.minX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

/// The window the island lives in: borderless, clear, above the menu bar, on
/// every Space and over full-screen apps, never taking focus from whatever the
/// person is working in.
final class NotchPanel: NSPanel {
  init() {
    super.init(
      contentRect: .zero,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false)
    isFloatingPanel = true
    level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
    collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    isMovable = false
    hidesOnDeactivate = false
    isReleasedWhenClosed = false
  }

  // Clicks reach its buttons without the panel ever becoming key: keyboard
  // focus stays with the app the person is typing in.
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
}

/// The island's SwiftUI, taking the first click: the panel is never key, so
/// without this every button would need two.
final class NotchHostingView: NSHostingView<NotchView> {
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Notices the pointer arriving at and leaving the island, whatever app is
/// active — SwiftUI's own hover only follows the key window.
final class NotchTrackingView: NSView {
  var onHover: ((Bool) -> Void)?

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    for area in trackingAreas { removeTrackingArea(area) }
    addTrackingArea(
      NSTrackingArea(
        rect: bounds,
        options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
        owner: self))
  }

  override func mouseEntered(with event: NSEvent) { onHover?(true) }
  override func mouseExited(with event: NSEvent) { onHover?(false) }
}

/// Shows the call at the notch, and grows it into its controls on hover.
@MainActor
final class NotchController {
  private let panel = NotchPanel()
  private var model: NotchModel?

  /// The pending grow or shrink: hovering has to settle for a moment before
  /// the island changes, so that sweeping the pointer across the top of the
  /// screen does not flash it open.
  private var pending: Task<Void, Never>?

  var isShowing: Bool { model != nil }

  func show(
    _ call: CallDescription,
    on geometry: NotchGeometry,
    onAction: @escaping (CallAction) -> Void,
    onOpen: @escaping () -> Void
  ) {
    if let model, model.geometry == geometry {
      model.call = call
      return
    }

    let model = NotchModel(call: call, geometry: geometry, onAction: onAction, onOpen: onOpen)
    let host = NotchHostingView(rootView: NotchView(model: model))
    let tracking = NotchTrackingView()
    tracking.onHover = { [weak self] inside in self?.hover(inside) }
    host.autoresizingMask = [.width, .height]
    tracking.addSubview(host)
    panel.contentView = tracking
    host.frame = tracking.bounds

    self.model = model
    panel.setFrame(geometry.frame(for: geometry.compactSize), display: true)
    panel.orderFrontRegardless()
  }

  func hide() {
    pending?.cancel()
    pending = nil
    model = nil
    panel.orderOut(nil)
    panel.contentView = nil
  }

  private func hover(_ inside: Bool) {
    pending?.cancel()
    pending = Task { @MainActor [weak self] in
      try? await Task.sleep(nanoseconds: inside ? 150_000_000 : 350_000_000)
      guard !Task.isCancelled else { return }
      if inside { self?.grow() } else { await self?.shrink() }
    }
  }

  private func grow() {
    guard let model, !model.expanded else { return }
    // The panel takes its largest size first and the island animates inside
    // it, rather than the window itself being animated.
    panel.setFrame(model.geometry.frame(for: model.geometry.expandedSize), display: true)
    model.expanded = true
  }

  private func shrink() async {
    guard let model, model.expanded else { return }
    model.expanded = false
    try? await Task.sleep(nanoseconds: 200_000_000)
    // Back to covering only the island once it has finished shrinking — so
    // the menu bar either side of it can be clicked again — unless the
    // pointer came back meanwhile.
    guard !Task.isCancelled, self.model === model, !model.expanded else { return }
    panel.setFrame(model.geometry.frame(for: model.geometry.compactSize), display: true)
  }
}
