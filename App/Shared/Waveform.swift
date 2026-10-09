import MemoKit
import SwiftUI

struct WaveformBars: View {
    var peaks: [Float]
    var duration: TimeInterval
    var visible: ClosedRange<TimeInterval>
    var playhead: TimeInterval
    var played: Color
    var unplayed: Color
    var barWidth: CGFloat = 2
    var spacing: CGFloat = 1.5
    var hidesFuture = false

    var body: some View {
        Canvas { context, size in
            guard visible.upperBound > visible.lowerBound else { return }
            let pitch = barWidth + spacing
            let secondsPerBar = (visible.upperBound - visible.lowerBound) / Double(size.width / pitch)
            let mid = size.height / 2
            let firstBar = Int((visible.lowerBound / secondsPerBar).rounded(.down))
            let lastBar = Int((visible.upperBound / secondsPerBar).rounded(.up))
            for bar in max(0, firstBar)...max(0, lastBar) {
                let start = Double(bar) * secondsPerBar
                guard start < duration else { break }
                let x = CGFloat((start - visible.lowerBound) / secondsPerBar) * pitch
                let level = Self.level(peaks, from: start, to: start + secondsPerBar)
                let isPast = start < playhead
                if hidesFuture, !isPast { continue }
                let height = max(1, CGFloat(level) * size.height * 0.96)
                let rect = CGRect(x: x, y: mid - height / 2, width: barWidth, height: height)
                context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2), with: .color(isPast ? played : unplayed))
            }
        }
    }

    static func level(_ peaks: [Float], from start: TimeInterval, to end: TimeInterval) -> Float {
        guard !peaks.isEmpty else { return 0 }
        let lower = min(peaks.count - 1, max(0, Int(start * Peaks.binsPerSecond)))
        let upper = min(peaks.count, max(lower + 1, Int((end * Peaks.binsPerSecond).rounded(.up))))
        return peaks[lower..<upper].max() ?? 0
    }
}
