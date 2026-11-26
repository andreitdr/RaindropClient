import ActivityKit
import SwiftUI
import WidgetKit

/// The widget extension: one Live Activity, the call this device is in.
///
/// The app starts it, keeps it current and ends it (`Runner/CallActivity.swift`);
/// this only draws it. See docs/background-and-live-calls.md.
@main
struct RaindropLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    CallLiveActivity()
  }
}

struct CallLiveActivity: Widget {
  /// How far the expanded island's content sits in from its sides, so all of
  /// it — the top row and the summary and buttons below — shares one edge.
  private static let inset: CGFloat = 12

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CallActivityAttributes.self) { context in
      CallLockScreenView(state: context.state)
        .activityBackgroundTint(Color.black.opacity(0.75))
        .activitySystemActionForegroundColor(.white)
        .foregroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        // The island's corners curve in tightly, so the top row is held in
        // from them — sideways and down — or the curve clips the microphone
        // and the timer's last digit.
        DynamicIslandExpandedRegion(.leading) {
          CallMicrophone(state: context.state)
            .font(.title2)
            .padding(.leading, Self.inset)
            .padding(.top, 6)
        }
        DynamicIslandExpandedRegion(.trailing) {
          CallTimer(state: context.state)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: 90, alignment: .trailing)
            .padding(.trailing, Self.inset)
            .padding(.top, 6)
        }
        // The summary sits with the controls, under the microphone and the
        // timer, rather than in the center region: iOS gives that only the
        // width between the leading and trailing regions and centers it
        // there, so the call's name would start halfway across while the
        // buttons below it start at the edge.
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 10) {
            CallSummary(state: context.state)
            CallControls(state: context.state)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, Self.inset)
          .padding(.bottom, 4)
        }
      } compactLeading: {
        CallMicrophone(state: context.state)
      } compactTrailing: {
        // A running timer takes as much room as its longest reading unless
        // held to a width.
        CallTimer(state: context.state)
          .font(.caption.weight(.semibold))
          .frame(maxWidth: 44)
      } minimal: {
        CallMicrophone(state: context.state)
      }
      .keylineTint(.green)
    }
  }
}
