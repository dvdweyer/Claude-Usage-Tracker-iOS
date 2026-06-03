import Foundation

struct Profile: Codable, Identifiable, Equatable {
    // MARK: - Identity
    let id: UUID
    var name: String

    // MARK: - Credentials
    // claudeSessionKey is excluded from Codable (see CodingKeys) — Keychain is the sole store.
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

    // MARK: - Codable — claudeSessionKey excluded; Keychain is sole store

    private enum CodingKeys: String, CodingKey {
        case id, name, organizationId, claudeUsage
        case refreshInterval, notificationSettings
        case createdAt, lastUsedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try c.decode(UUID.self,                 forKey: .id)
        name                 = try c.decode(String.self,               forKey: .name)
        organizationId       = try c.decodeIfPresent(String.self,      forKey: .organizationId)
        claudeUsage          = try c.decodeIfPresent(ClaudeUsage.self, forKey: .claudeUsage)
        refreshInterval      = try c.decode(TimeInterval.self,         forKey: .refreshInterval)
        notificationSettings = try c.decode(NotificationSettings.self, forKey: .notificationSettings)
        createdAt            = try c.decode(Date.self,                 forKey: .createdAt)
        lastUsedAt           = try c.decode(Date.self,                 forKey: .lastUsedAt)
        claudeSessionKey     = nil  // always hydrated from Keychain by ProfileManager
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
