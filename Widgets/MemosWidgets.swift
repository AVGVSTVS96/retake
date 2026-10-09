import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct MemosWidgets: WidgetBundle {
    var body: some Widget {
        RecordingLiveActivity()
        RecordControl()
    }
}

struct RecordControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.shahidy.memos.record") {
            ControlWidgetButton(action: RecordVoiceMemoIntent()) {
                Label("Voice Memo", systemImage: "waveform")
            }
        }
        .displayName("Voice Memo")
        .description("Record personal notes, musical ideas, and more.")
    }
}

struct RecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivity.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .symbolEffect(.variableColor.iterative, isActive: context.state.pausedElapsed == nil)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.title).font(.headline)
                    Text(context.state.pausedElapsed == nil ? "Recording" : "Paused")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Elapsed(state: context.state)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.red)
                Button(intent: StopRecordingIntent()) {
                    Image(systemName: "stop.fill").foregroundStyle(.red)
                }
                .buttonBorderShape(.circle)
            }
            .padding(16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.red)
                        .symbolEffect(.variableColor.iterative, isActive: context.state.pausedElapsed == nil)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Elapsed(state: context.state).foregroundStyle(.red).padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.title).font(.headline)
                        Spacer()
                        Button(intent: StopRecordingIntent()) {
                            Image(systemName: "stop.fill").foregroundStyle(.red)
                        }
                        .buttonBorderShape(.circle)
                    }
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                Image(systemName: "waveform")
                    .foregroundStyle(.red)
                    .symbolEffect(.variableColor.iterative, isActive: context.state.pausedElapsed == nil)
            } compactTrailing: {
                Elapsed(state: context.state)
                    .foregroundStyle(.red)
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "waveform").foregroundStyle(.red)
            }
            .keylineTint(.red)
        }
    }
}

private struct Elapsed: View {
    let state: RecordingActivity.ContentState

    var body: some View {
        Group {
            if let paused = state.pausedElapsed {
                Text(Duration.seconds(paused), format: .time(pattern: .minuteSecond))
            } else {
                Text(timerInterval: state.started...Date.distantFuture, countsDown: false)
            }
        }
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
}
