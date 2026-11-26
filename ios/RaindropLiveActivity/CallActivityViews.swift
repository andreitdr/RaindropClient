import AppIntents
import SwiftUI

// What the call's Live Activity draws, from its state alone. Kept apart from
// the activity's configuration (RaindropLiveActivity.swift) so that nothing
// here needs ActivityKit: every presentation is a plain view of a
// CallActivityAttributes.ContentState.

/// The microphone as everybody else hears it: green while talking is heard,
/// red when nothing is.
struct CallMicrophone: View {
  let state: CallActivityAttributes.ContentState

  var body: some View {
    Image(systemName: state.microphoneSymbol)
      .foregroundColor(state.micOn && !state.deafened ? .green : .red)
  }
}

/// How long the call has run, drawn and kept current by the system — or what
/// is happening instead.
struct CallTimer: View {
  let state: CallActivityAttributes.ContentState

  var body: some View {
    if state.reconnecting {
      Image(systemName: "arrow.triangle.2.circlepath")
        .foregroundColor(.orange)
    } else if let connectedAt = state.connectedAt {
      Text(timerInterval: connectedAt...Date.distantFuture, countsDown: false)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    } else {
      Text("0:00").monospacedDigit()
    }
  }
}

/// The call's name, its server, and who is in it.
struct CallSummary: View {
  let state: CallActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(state.reconnecting ? "Reconnecting…" : state.title)
        .font(.headline)
        .lineLimit(1)
      HStack(spacing: 6) {
        if !state.body.isEmpty {
          Text(state.body).lineLimit(1)
        }
        if state.participants > 0 {
          Label("\(state.participants)", systemImage: "person.2.fill")
        }
        if state.sharingScreen {
          Image(systemName: "rectangle.on.rectangle")
        }
        if state.encrypted {
          Image(systemName: "lock.fill")
        }
      }
      .font(.caption)
      .foregroundColor(.secondary)
    }
  }
}

/// Mute, deafen and leave — where the system can run them from outside the
/// app (iOS 17 and later). Before that, the activity is a way back into the
/// app, which opens on a tap.
struct CallControls: View {
  let state: CallActivityAttributes.ContentState

  var body: some View {
    if #available(iOS 17.0, *) {
      HStack(spacing: 12) {
        Button(intent: ToggleMuteCallIntent()) {
          CallControlFace(
            symbol: state.micOn ? "mic.fill" : "mic.slash.fill",
            alarmed: !state.micOn)
        }
        Button(intent: ToggleDeafenCallIntent()) {
          CallControlFace(
            symbol: state.deafened ? "speaker.slash.fill" : "speaker.wave.2.fill",
            alarmed: state.deafened)
        }
        Spacer(minLength: 0)
        Button(intent: LeaveCallIntent()) {
          CallControlFace(symbol: "phone.down.fill", alarmed: true)
        }
      }
      .buttonStyle(.plain)
    }
  }
}

/// One round control.
struct CallControlFace: View {
  let symbol: String
  let alarmed: Bool

  var body: some View {
    Image(systemName: symbol)
      .font(.system(size: 15, weight: .semibold))
      .foregroundColor(.white)
      .frame(width: 40, height: 40)
      .background(Circle().fill(alarmed ? Color.red : Color.gray.opacity(0.35)))
  }
}

/// The Lock Screen and Notification Center banner — what every iPhone shows,
/// and all that one without a Dynamic Island has.
struct CallLockScreenView: View {
  let state: CallActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 12) {
        CallMicrophone(state: state)
          .font(.title2)
          .frame(width: 32)
        CallSummary(state: state)
        Spacer(minLength: 8)
        CallTimer(state: state)
          .font(.title3.weight(.semibold))
          .frame(maxWidth: 90, alignment: .trailing)
      }
      CallControls(state: state)
    }
    .padding(16)
  }
}
