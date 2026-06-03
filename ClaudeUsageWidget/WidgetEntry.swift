import WidgetKit
import Foundation

struct ClaudeUsageEntry: TimelineEntry {
    let date: Date
    let sessionPercentage: Double
    let weeklyPercentage: Double
    let sessionResetTime: Date
    let weeklyResetTime: Date
    let profileName: String
    let hasData: Bool
    let opusPercentage: Double
    let sonnetPercentage: Double

    static var placeholder: ClaudeUsageEntry {
        ClaudeUsageEntry(
            date: Date(),
            sessionPercentage: 65,
            weeklyPercentage: 42,
            sessionResetTime: Date().addingTimeInterval(2 * 3600),
            weeklyResetTime: Date().addingTimeInterval(4 * 24 * 3600),
            profileName: "Claude",
            hasData: true,
            opusPercentage: 30,
            sonnetPercentage: 45
        )
    }

    static var empty: ClaudeUsageEntry {
        ClaudeUsageEntry(
            date: Date(),
            sessionPercentage: 0,
            weeklyPercentage: 0,
            sessionResetTime: Date().addingTimeInterval(5 * 3600),
            weeklyResetTime: Date().addingTimeInterval(7 * 24 * 3600),
            profileName: "Claude",
            hasData: false,
            opusPercentage: 0,
            sonnetPercentage: 0
        )
    }

    static func from(usage: ClaudeUsage, profileName: String) -> ClaudeUsageEntry {
        ClaudeUsageEntry(
            date: usage.lastUpdated,
            sessionPercentage: usage.effectiveSessionPercentage,
            weeklyPercentage: usage.weeklyPercentage,
            sessionResetTime: usage.sessionResetTime,
            weeklyResetTime: usage.weeklyResetTime,
            profileName: profileName,
            hasData: true,
            opusPercentage: usage.opusWeeklyPercentage,
            sonnetPercentage: usage.sonnetWeeklyPercentage
        )
    }
}
