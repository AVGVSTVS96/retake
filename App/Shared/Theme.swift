import SwiftUI

extension Color {
    static let record = Color(.systemRed)
    static let rowDetail = Color.primary.opacity(0.55)
    static let waveformTrack = Color(.secondarySystemFill)
    static let panel = Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray5 : .systemGray6 })
}

enum Metrics {
    static let recordDot: CGFloat = 52
    static let recordRing: CGFloat = 3
    static let compactSheet: CGFloat = 257
    static let rowInset: CGFloat = 20
}
