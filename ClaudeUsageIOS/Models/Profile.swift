import Foundation

struct Profile: Codable, Identifiable, Equatable {
    // MARK: - Identity
    let id: UUID
    var name: String

    // MARK: - Credentials
    var claudeSessionKey: String?
    var organizationId: String?

    // MARK: - Usage Data
    var claudeUsage: ClaudeUsage?

    // MARK: - Settings
    var refreshInterval: TimeInterval
    var notificationSettings: NotificationSettings

    // MARK: - Metadata
    var createdAt: Date
    var lastUsedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        claudeSessionKey: String? = nil,
        organizationId: String? = nil,
        claudeUsage: ClaudeUsage? = nil,
        refreshInterval: TimeInterval = 30.0,
        notificationSettings: NotificationSettings = NotificationSettings(),
        createdAt: Date = Date(),
        lastUsedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.claudeSessionKey = claudeSessionKey
        self.organizationId = organizationId
        self.claudeUsage = claudeUsage
        self.refreshInterval = refreshInterval
        self.notificationSettings = notificationSettings
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    // MARK: - Persistence

    func strippingCredentials() -> Profile {
        var copy = self
        copy.claudeSessionKey = nil
        return copy
    }

    // MARK: - Computed

    var hasClaudeAI: Bool {
        claudeSessionKey != nil && organizationId != nil
    }

    var hasUsageCredentials: Bool {
        claudeSessionKey != nil
    }

    var hasAnyCredentials: Bool {
        claudeSessionKey != nil
    }
}
