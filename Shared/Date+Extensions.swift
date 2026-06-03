import Foundation

extension Date {
    func nextMonday1259pm(in timezone: TimeZone = .current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone

        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: self)

        let currentWeekday = components.weekday ?? 1
        let daysUntilMonday = currentWeekday == 2 ? 7 : (9 - currentWeekday) % 7

        guard let nextMonday = calendar.date(byAdding: .day, value: daysUntilMonday, to: self) else {
            return self
        }

        components = calendar.dateComponents([.year, .month, .day], from: nextMonday)
        components.hour = 12
        components.minute = 59
        components.second = 0

        return calendar.date(from: components) ?? self
    }

    func timeRemainingString(from now: Date = Date()) -> String {
        let interval = self.timeIntervalSince(now)

        if interval < 0 { return "Reset now" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let days = hours / 24

        if days > 0 {
            let remainingHours = hours % 24
            if remainingHours > 0 { return "\(days)d \(remainingHours)h" }
            return days == 1 ? "1 day" : "\(days) days"
        } else if hours > 0 {
            if minutes > 0 { return "\(hours)h \(minutes)m" }
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }

    func resetTimeString(from now: Date = Date(), timezone: TimeZone = .current) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        let timeFmt = Date.systemUses24HourTime ? "HH:mm" : "h:mma"

        if calendar.isDateInToday(self) {
            formatter.dateFormat = "'Today' \(timeFmt)"
        } else if calendar.isDateInTomorrow(self) {
            formatter.dateFormat = "'Tomorrow' \(timeFmt)"
        } else {
            formatter.dateFormat = "MMM d, \(timeFmt)"
        }

        return formatter.string(from: self)
    }

    private static var systemUses24HourTime: Bool {
        DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?.contains("a") == false
    }
}
