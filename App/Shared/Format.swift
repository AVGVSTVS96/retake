import Foundation

enum Format {
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.toNearestOrAwayFromZero))
        let (hours, minutes, secs) = (total / 3600, total / 60 % 60, total % 60)
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }

    static func remaining(_ seconds: TimeInterval) -> String {
        "-" + duration(seconds)
    }

    static func timer(_ seconds: TimeInterval) -> String {
        let hundredths = Int((seconds * 100).rounded(.down))
        let (hours, minutes, secs, fraction) = (hundredths / 360_000, hundredths / 6000 % 60, hundredths / 100 % 60, hundredths % 100)
        return hours > 0
            ? String(format: "%d:%02d:%02d.%02d", hours, minutes, secs, fraction)
            : String(format: "%02d:%02d.%02d", minutes, secs, fraction)
    }

    static func ruler(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return total >= 3600
            ? String(format: "%d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
            : String(format: "%d:%02d", total / 60, total % 60)
    }

    static func listDate(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if days < 7 {
            return date.formatted(.dateTime.weekday(.wide))
        }
        return date.formatted(.dateTime.month(.wide).day().year())
    }

    static func headerDate(_ date: Date, now: Date = .now) -> String {
        Calendar.current.isDate(date, inSameDayAs: now)
            ? date.formatted(date: .omitted, time: .shortened)
            : listDate(date, now: now)
    }
}
