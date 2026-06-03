import Foundation

struct AppError: Error, LocalizedError, CustomStringConvertible {
    let code: ErrorCode
    let message: String
    let technicalDetails: String?
    let underlyingError: Error?
    let timestamp: Date
    let isRecoverable: Bool
    let recoverySuggestion: String?

    init(
        code: ErrorCode,
        message: String,
        technicalDetails: String? = nil,
        underlyingError: Error? = nil,
        isRecoverable: Bool = true,
        recoverySuggestion: String? = nil
    ) {
        self.code = code
        self.message = message
        self.technicalDetails = technicalDetails
        self.underlyingError = underlyingError
        self.timestamp = Date()
        self.isRecoverable = isRecoverable
        self.recoverySuggestion = recoverySuggestion
    }

    var errorDescription: String? { message }
    var failureReason: String? { technicalDetails }

    var description: String {
        var desc = "[\(code.rawValue)] \(message)"
        if let details = technicalDetails { desc += "\nDetails: \(details)" }
        return desc
    }
}

// MARK: - Error Codes

enum ErrorCode: String {
    case sessionKeyNotFound = "E1000"
    case sessionKeyInvalid = "E1001"
    case sessionKeyExpired = "E1002"
    case sessionKeyTooShort = "E1003"
    case sessionKeyTooLong = "E1004"
    case sessionKeyInvalidPrefix = "E1005"
    case sessionKeyInvalidCharacters = "E1006"
    case sessionKeyInvalidFormat = "E1007"
    case sessionKeyMalicious = "E1008"
    case sessionKeyWhitespace = "E1009"
    case sessionKeyStorageFailed = "E1010"

    case networkUnavailable = "E2000"
    case networkTimeout = "E2001"
    case networkGenericError = "E2099"

    case apiUnauthorized = "E3000"
    case apiInvalidResponse = "E3001"
    case apiServerError = "E3002"
    case apiRateLimited = "E3003"
    case apiParsingFailed = "E3007"
    case apiGenericError = "E3099"

    case urlInvalidBase = "E4000"
    case urlInvalidPath = "E4001"
    case urlInvalidQuery = "E4002"
    case urlMalformed = "E4003"

    case storageReadFailed = "E5000"
    case storageWriteFailed = "E5001"

    case unknown = "E9999"
}

// MARK: - Convenience Constructors

extension AppError {
    static func sessionKeyNotFound() -> AppError {
        AppError(
            code: .sessionKeyNotFound,
            message: "No session key found.",
            technicalDetails: "Session key not configured for this profile.",
            isRecoverable: true,
            recoverySuggestion: "Add your Claude session key in profile settings."
        )
    }

    static func apiUnauthorized() -> AppError {
        AppError(
            code: .apiUnauthorized,
            message: "Unauthorized. Your session key may have expired.",
            isRecoverable: true,
            recoverySuggestion: "Update your session key in profile settings."
        )
    }

    static func apiRateLimited() -> AppError {
        AppError(
            code: .apiRateLimited,
            message: "Rate limited by Claude API.",
            isRecoverable: true,
            recoverySuggestion: "Please wait a few minutes before trying again."
        )
    }

    static func wrap(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        if let validationError = error as? SessionKeyValidationError {
            return fromSessionKeyValidationError(validationError)
        }
        if let urlError = error as? URLBuilderError {
            return fromURLBuilderError(urlError)
        }
        return AppError(
            code: .unknown,
            message: error.localizedDescription,
            technicalDetails: "\(type(of: error)): \(error)",
            underlyingError: error,
            isRecoverable: true
        )
    }

    private static func fromSessionKeyValidationError(_ error: SessionKeyValidationError) -> AppError {
        switch error {
        case .empty:
            return sessionKeyNotFound()
        case .tooShort(let min, let actual):
            return AppError(code: .sessionKeyTooShort, message: "Session key too short.", technicalDetails: "Min: \(min), Actual: \(actual)")
        case .tooLong(let max, let actual):
            return AppError(code: .sessionKeyTooLong, message: "Session key too long.", technicalDetails: "Max: \(max), Actual: \(actual)")
        case .invalidPrefix:
            return AppError(code: .sessionKeyInvalidPrefix, message: "Session key must start with 'sk-ant-'.")
        case .invalidCharacters:
            return AppError(code: .sessionKeyInvalidCharacters, message: "Session key contains invalid characters.")
        case .invalidFormat:
            return AppError(code: .sessionKeyInvalidFormat, message: "Invalid session key format.")
        case .potentiallyMalicious:
            return AppError(code: .sessionKeyMalicious, message: "Session key rejected for security reasons.")
        case .containsWhitespace:
            return AppError(code: .sessionKeyWhitespace, message: "Session key cannot contain whitespace.")
        }
    }

    private static func fromURLBuilderError(_ error: URLBuilderError) -> AppError {
        switch error {
        case .invalidBaseURL(let url):
            return AppError(code: .urlInvalidBase, message: "Invalid base URL.", technicalDetails: url)
        case .invalidPath(let path):
            return AppError(code: .urlInvalidPath, message: "Invalid URL path.", technicalDetails: path)
        case .invalidQueryParameter(let key, let value):
            return AppError(code: .urlInvalidQuery, message: "Invalid query parameter.", technicalDetails: "\(key)=\(value)")
        case .malformedURL(let details):
            return AppError(code: .urlMalformed, message: "Malformed URL.", technicalDetails: details)
        }
    }
}
