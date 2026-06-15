import Foundation
import UserNotifications

struct NotificationSettings: Codable, Equatable {
    var enabled: Bool
    var threshold75Enabled: Bool
    var threshold90Enabled: Bool
    var threshold95Enabled: Bool
    var soundName: String
    var customThresholds: [Int]
    var resetNotificationEnabled: Bool

    var sortedThresholds: [Int] {
        var thresholds: [Int] = []
        if threshold75Enabled { thresholds.append(75) }
        if threshold90Enabled { thresholds.append(90) }
        if threshold95Enabled { thresholds.append(95) }
        thresholds.append(contentsOf: customThresholds)
        return Array(Set(thresholds)).sorted()
    }

    var notificationSound: UNNotificationSound? {
        switch soundName {
        case "none": return nil
        case "default": return .default
        default: return UNNotificationSound(named: UNNotificationSoundName(soundName))
        }
    }

    init(
        enabled: Bool = true,
        threshold75Enabled: Bool = true,
        threshold90Enabled: Bool = true,
        threshold95Enabled: Bool = true,
        soundName: String = "default",
        customThresholds: [Int] = [],
        resetNotificationEnabled: Bool = true
    ) {
        self.enabled = enabled
        self.threshold75Enabled = threshold75Enabled
        self.threshold90Enabled = threshold90Enabled
        self.threshold95Enabled = threshold95Enabled
        self.soundName = soundName
        self.customThresholds = customThresholds
        self.resetNotificationEnabled = resetNotificationEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        threshold75Enabled = try container.decode(Bool.self, forKey: .threshold75Enabled)
        threshold90Enabled = try container.decode(Bool.self, forKey: .threshold90Enabled)
        threshold95Enabled = try container.decode(Bool.self, forKey: .threshold95Enabled)
        soundName = try container.decodeIfPresent(String.self, forKey: .soundName) ?? "default"
        customThresholds = try container.decodeIfPresent([Int].self, forKey: .customThresholds) ?? []
        resetNotificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .resetNotificationEnabled) ?? true
    }
}
