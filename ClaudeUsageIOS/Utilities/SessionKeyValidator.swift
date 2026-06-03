import Foundation

enum SessionKeyValidationError: LocalizedError {
    case empty
    case tooShort(minLength: Int, actualLength: Int)
    case tooLong(maxLength: Int, actualLength: Int)
    case invalidPrefix(expected: String)
    case invalidCharacters(String)
    case invalidFormat(String)
    case containsWhitespace
    case potentiallyMalicious(String)

    var errorDescription: String? {
        switch self {
        case .empty: return "Session key cannot be empty"
        case .tooShort(let min, let actual): return "Session key too short (minimum: \(min), actual: \(actual))"
        case .tooLong(let max, let actual): return "Session key too long (maximum: \(max), actual: \(actual))"
        case .invalidPrefix(let expected): return "Session key must start with '\(expected)'"
        case .invalidCharacters(let desc): return "Session key contains invalid characters: \(desc)"
        case .invalidFormat(let desc): return "Invalid session key format: \(desc)"
        case .containsWhitespace: return "Session key cannot contain whitespace"
        case .potentiallyMalicious(let reason): return "Session key rejected for security: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .empty, .tooShort, .tooLong:
            return "Copy the complete sessionKey cookie value from your browser's DevTools"
        case .invalidPrefix:
            return "The session key should start with 'sk-ant-'"
        case .invalidCharacters, .invalidFormat:
            return "The session key may be corrupted. Please copy it again from your browser"
        case .containsWhitespace:
            return "Remove any spaces or newlines from the session key"
        case .potentiallyMalicious:
            return "Please verify the session key is from a legitimate source"
        }
    }
}

struct SessionKeyValidator {
    struct Configuration {
        let requiredPrefix: String
        let minLength: Int
        let maxLength: Int
        let allowedCharacterSet: CharacterSet
        let strictMode: Bool

        static let `default` = Configuration(
            requiredPrefix: "sk-ant-",
            minLength: 20,
            maxLength: 500,
            allowedCharacterSet: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"),
            strictMode: true
        )
    }

    private let configuration: Configuration

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    @discardableResult
    func validate(_ sessionKey: String) throws -> String {
        let trimmed = sessionKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { throw SessionKeyValidationError.empty }

        if configuration.strictMode && trimmed.contains(where: { $0.isWhitespace }) {
            throw SessionKeyValidationError.containsWhitespace
        }

        guard trimmed.count >= configuration.minLength else {
            throw SessionKeyValidationError.tooShort(minLength: configuration.minLength, actualLength: trimmed.count)
        }

        guard trimmed.count <= configuration.maxLength else {
            throw SessionKeyValidationError.tooLong(maxLength: configuration.maxLength, actualLength: trimmed.count)
        }

        guard trimmed.hasPrefix(configuration.requiredPrefix) else {
            throw SessionKeyValidationError.invalidPrefix(expected: configuration.requiredPrefix)
        }

        if configuration.strictMode { try performSecurityChecks(trimmed) }

        let invalidCharacters = trimmed.unicodeScalars.filter { !configuration.allowedCharacterSet.contains($0) }
        if !invalidCharacters.isEmpty {
            throw SessionKeyValidationError.invalidCharacters("Found disallowed characters: '\(String(String.UnicodeScalarView(invalidCharacters)))'")
        }

        try validateFormat(trimmed)
        return trimmed
    }

    func isValid(_ sessionKey: String) -> Bool {
        (try? validate(sessionKey)) != nil
    }

    func validationStatus(_ sessionKey: String) -> (isValid: Bool, errorMessage: String?) {
        do {
            try validate(sessionKey)
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func performSecurityChecks(_ key: String) throws {
        if key.contains("\0") { throw SessionKeyValidationError.potentiallyMalicious("Contains null bytes") }
        if key.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) {
            throw SessionKeyValidationError.potentiallyMalicious("Contains control characters")
        }
        if key.contains("..") || key.contains("//") {
            throw SessionKeyValidationError.potentiallyMalicious("Contains suspicious patterns")
        }
        let suspiciousPatterns = ["<script", "javascript:", "data:", "vbscript:", "file:"]
        for pattern in suspiciousPatterns {
            if key.lowercased().contains(pattern) {
                throw SessionKeyValidationError.potentiallyMalicious("Contains script injection pattern")
            }
        }
    }

    private func validateFormat(_ key: String) throws {
        let afterPrefix = String(key.dropFirst(configuration.requiredPrefix.count))
        guard !afterPrefix.isEmpty else {
            throw SessionKeyValidationError.invalidFormat("No content after prefix")
        }
        guard afterPrefix.contains("-") || afterPrefix.contains("_") else {
            throw SessionKeyValidationError.invalidFormat("Missing expected separators")
        }
    }
}

extension String {
    func validateAsSessionKey() throws -> String {
        try SessionKeyValidator().validate(self)
    }

    var isValidSessionKey: Bool {
        SessionKeyValidator().isValid(self)
    }
}
