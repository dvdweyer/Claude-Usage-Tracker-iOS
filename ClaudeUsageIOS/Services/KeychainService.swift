import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    enum KeychainKey: String {
        case claudeSessionKey = "org.afaik.claudeusagetracker.ios.claude-session-key"
        case apiSessionKey = "org.afaik.claudeusagetracker.ios.api-session-key"

        var service: String { rawValue }
        var account: String { "user-credential" }
    }

    func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if updateStatus == errSecSuccess { return }

        if updateStatus == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: key.service,
                kSecAttrAccount as String: key.account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw KeychainError.saveFailed(status: addStatus)
            }
        } else {
            throw KeychainError.saveFailed(status: updateStatus)
        }
    }

    func load(for key: KeychainKey) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return value
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.loadFailed(status: status)
        }
    }

    func delete(for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    func exists(for key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
            kSecReturnData as String: false
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
}

enum KeychainError: Error, LocalizedError {
    case invalidData
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData: return "Invalid data format for Keychain storage"
        case .saveFailed(let s): return "Failed to save to Keychain (OSStatus: \(s))"
        case .loadFailed(let s): return "Failed to load from Keychain (OSStatus: \(s))"
        case .deleteFailed(let s): return "Failed to delete from Keychain (OSStatus: \(s))"
        }
    }
}
