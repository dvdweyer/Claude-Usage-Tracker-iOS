import Foundation

enum Constants {
    static let appGroupIdentifier = "group.org.afaik.claudeusagetracker.shared"

    static let sessionWindow: TimeInterval = 5 * 60 * 60
    static let weeklyWindow: TimeInterval = 7 * 24 * 60 * 60
    static let weeklyLimit = 1_000_000

    enum APIEndpoints {
        static let claudeBase = "https://claude.ai/api"
        static let consoleBase = "https://console.anthropic.com/api"
    }

    enum RefreshIntervals {
        static let defaultRefresh: TimeInterval = 30
        static let widgetRefresh: TimeInterval = 900
    }

    enum NotificationThresholds {
        static let warning: Double = 75.0
        static let high: Double = 90.0
        static let critical: Double = 95.0
    }
}
