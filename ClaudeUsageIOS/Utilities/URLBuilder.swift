import Foundation

enum URLBuilderError: LocalizedError {
    case invalidBaseURL(String)
    case invalidPath(String)
    case invalidQueryParameter(key: String, value: String)
    case malformedURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL(let url): return "Invalid base URL: \(url)"
        case .invalidPath(let path): return "Invalid URL path: \(path)"
        case .invalidQueryParameter(let key, let value): return "Invalid query parameter: \(key)=\(value)"
        case .malformedURL(let desc): return "Malformed URL: \(desc)"
        }
    }
}

struct URLBuilder {
    private var components: URLComponents

    init(baseURL: String) throws {
        guard let components = URLComponents(string: baseURL) else {
            throw URLBuilderError.invalidBaseURL(baseURL)
        }
        guard components.scheme != nil, components.host != nil else {
            throw URLBuilderError.invalidBaseURL("Missing scheme or host")
        }
        self.components = components
    }

    init(components: URLComponents) {
        self.components = components
    }

    func appendingPath(_ path: String) throws -> URLBuilder {
        var newComponents = components
        let cleanPath = path.trimmingCharacters(in: .whitespaces)
        guard !cleanPath.contains("..") else {
            throw URLBuilderError.invalidPath("Path contains '..'")
        }
        let trimmedPath = cleanPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let currentPath = newComponents.path
        if currentPath.isEmpty {
            newComponents.path = "/" + trimmedPath
        } else {
            let needsSlash = !currentPath.hasSuffix("/")
            newComponents.path = currentPath + (needsSlash ? "/" : "") + trimmedPath
        }
        return URLBuilder(components: newComponents)
    }

    func appendingPathComponents(_ paths: [String]) throws -> URLBuilder {
        var builder = self
        for path in paths { builder = try builder.appendingPath(path) }
        return builder
    }

    func addingQueryParameter(name: String, value: String) throws -> URLBuilder {
        guard !name.isEmpty else {
            throw URLBuilderError.invalidQueryParameter(key: name, value: "Empty parameter name")
        }
        var newComponents = components
        var queryItems = newComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        newComponents.queryItems = queryItems
        return URLBuilder(components: newComponents)
    }

    func build() throws -> URL {
        guard let url = components.url else {
            throw URLBuilderError.malformedURL("Failed to construct URL from components")
        }
        guard let scheme = components.scheme, ["http", "https"].contains(scheme) else {
            throw URLBuilderError.malformedURL("Invalid or missing URL scheme")
        }
        return url
    }
}

extension URLBuilder {
    static func claudeAPI(endpoint: String = "") throws -> URLBuilder {
        let builder = try URLBuilder(baseURL: "https://claude.ai/api")
        return endpoint.isEmpty ? builder : try builder.appendingPath(endpoint)
    }

    static func consoleAPI(endpoint: String = "") throws -> URLBuilder {
        let builder = try URLBuilder(baseURL: "https://console.anthropic.com/api")
        return endpoint.isEmpty ? builder : try builder.appendingPath(endpoint)
    }
}
