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
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CallActivityAttributes.self) { context in
      CallLockScreenView(state: context.state)
        .activityBackgroundTint(Color.black.opacity(0.75))
        .activitySystemActionForegroundColor(.white)
        .foregroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          CallMicrophone(state: context.state)
            .font(.title2)
            .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          CallTimer(state: context.state)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: 90, alignment: .trailing)
        }
        DynamicIslandExpandedRegion(.center) {
          CallSummary(state: context.state)
        }
        DynamicIslandExpandedRegion(.bottom) {
          CallControls(state: context.state)
            .padding(.top, 4)
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
