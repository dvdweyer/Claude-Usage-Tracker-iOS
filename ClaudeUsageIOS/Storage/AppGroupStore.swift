import Foundation
import WidgetKit

/// Writes usage data to the shared App Group UserDefaults so the widget can read it.
final class AppGroupStore {
    static let shared = AppGroupStore()

    private let defaults: UserDefaults?
    private let usageKey = "widget.claudeUsage"
    private let profileNameKey = "widget.profileName"
    private let lastUpdateKey = "widget.lastUpdate"
    private let sessionKeyKey = "widget.sessionKey"
    private let orgIdKey = "widget.orgId"

    private init() {
        defaults = UserDefaults(suiteName: Constants.appGroupIdentifier)
    }

    func writeUsage(_ usage: ClaudeUsage, profileName: String) {
        guard let defaults else { return }
        if let data = try? JSONEncoder().encode(usage) {
            defaults.set(data, forKey: usageKey)
        }
        defaults.set(profileName, forKey: profileNameKey)
        defaults.set(Date(), forKey: lastUpdateKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func readUsage() -> ClaudeUsage? {
        guard let defaults,
              let data = defaults.data(forKey: usageKey) else { return nil }
        return try? JSONDecoder().decode(ClaudeUsage.self, from: data)
    }

    func readProfileName() -> String {
        defaults?.string(forKey: profileNameKey) ?? "Claude"
    }

    func readLastUpdate() -> Date? {
        defaults?.object(forKey: lastUpdateKey) as? Date
    }

    func writeCredentials(sessionKey: String, orgId: String) {
        defaults?.set(sessionKey, forKey: sessionKeyKey)
        defaults?.set(orgId, forKey: orgIdKey)
    }

    func readSessionKey() -> String? {
        defaults?.string(forKey: sessionKeyKey)
    }

    func readOrgId() -> String? {
        defaults?.string(forKey: orgIdKey)
    }
}
