import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private enum ID {
        static let sessionReset = "session-reset"
        static let weeklyReset = "weekly-reset"
        static func threshold(_ pct: Int) -> String { "threshold-\(pct)" }
    }

    private enum DefaultsKey {
        static let firedThresholds = "notification.firedThresholds"
        static let lastSessionResetTime = "notification.lastSessionResetTime"
    }

    // MARK: - Public

    func handleUsageUpdate(_ usage: ClaudeUsage, settings: NotificationSettings) {
        guard settings.enabled else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }

        resetFiredThresholdsIfNewSession(resetTime: usage.sessionResetTime)
        scheduleResetNotifications(usage: usage, settings: settings)
        fireThresholdNotificationsIfNeeded(usage: usage, settings: settings)
    }

    // MARK: - Reset Notifications

    private func scheduleResetNotifications(usage: ClaudeUsage, settings: NotificationSettings) {
        let center = UNUserNotificationCenter.current()

        if settings.resetNotificationEnabled {
            schedule(
                id: ID.sessionReset,
                title: "Session Reset",
                body: "Your 5-hour Claude session has reset — you're back to 0%.",
                at: usage.sessionResetTime,
                sound: settings.notificationSound
            )
            schedule(
                id: ID.weeklyReset,
                title: "Weekly Usage Reset",
                body: "Your weekly Claude usage has reset.",
                at: usage.weeklyResetTime,
                sound: settings.notificationSound
            )
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [ID.sessionReset, ID.weeklyReset])
        }
    }

    private func schedule(id: String, title: String, body: String, at date: Date, sound: UNNotificationSound?) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound ?? .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Threshold Notifications

    private func resetFiredThresholdsIfNewSession(resetTime: Date) {
        let last = UserDefaults.standard.object(forKey: DefaultsKey.lastSessionResetTime) as? Date
        if last != resetTime {
            UserDefaults.standard.set([] as [Int], forKey: DefaultsKey.firedThresholds)
            UserDefaults.standard.set(resetTime, forKey: DefaultsKey.lastSessionResetTime)
        }
    }

    private func fireThresholdNotificationsIfNeeded(usage: ClaudeUsage, settings: NotificationSettings) {
        guard usage.effectiveSessionPercentage > 0 else { return }

        let currentPct = Int(usage.effectiveSessionPercentage)
        var fired = Set(UserDefaults.standard.array(forKey: DefaultsKey.firedThresholds) as? [Int] ?? [])

        for threshold in settings.sortedThresholds where currentPct >= threshold && !fired.contains(threshold) {
            fire(
                id: ID.threshold(threshold),
                title: "Claude Usage Alert",
                body: "Session usage has reached \(threshold)%.",
                sound: settings.notificationSound
            )
            fired.insert(threshold)
        }

        UserDefaults.standard.set(Array(fired), forKey: DefaultsKey.firedThresholds)
    }

    private func fire(id: String, title: String, body: String, sound: UNNotificationSound?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound ?? .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
