import Foundation

struct Profile: Codable, Identifiable, Equatable {
    // MARK: - Identity
    let id: UUID
    var name: String

    // MARK: - Credentials
    var claudeSessionKey: String?
    var organizationId: String?
    var apiSessionKey: String?
    var apiOrganizationId: String?
    var apiSessionKeyExpiry: Date?

    // MARK: - Usage Data
    var claudeUsage: ClaudeUsage?
    var apiUsage: APIUsage?

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
        apiSessionKey: String? = nil,
        apiOrganizationId: String? = nil,
        apiSessionKeyExpiry: Date? = nil,
        claudeUsage: ClaudeUsage? = nil,
        apiUsage: APIUsage? = nil,
        refreshInterval: TimeInterval = 30.0,
        notificationSettings: NotificationSettings = NotificationSettings(),
        createdAt: Date = Date(),
        lastUsedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.claudeSessionKey = claudeSessionKey
        self.organizationId = organizationId
        self.apiSessionKey = apiSessionKey
        self.apiOrganizationId = apiOrganizationId
        self.apiSessionKeyExpiry = apiSessionKeyExpiry
        self.claudeUsage = claudeUsage
        self.apiUsage = apiUsage
        self.refreshInterval = refreshInterval
        self.notificationSettings = notificationSettings
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    // MARK: - Computed

    var hasClaudeAI: Bool {
        claudeSessionKey != nil && organizationId != nil
    }

    var hasAPIConsole: Bool {
        apiSessionKey != nil && apiOrganizationId != nil
    }

    /// A session key alone is enough — the org ID is auto-fetched on first use.
    var hasUsageCredentials: Bool {
        claudeSessionKey != nil
    }

    var hasAnyCredentials: Bool {
        claudeSessionKey != nil || apiSessionKey != nil
    }
}
