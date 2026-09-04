import Foundation
@_exported import PrismCore
import PrismLogging

/// Parameter container holding extracted route segments and query items.
public struct RouteParameters: Sendable, Equatable {
    public let pathParameters: [String: String]
    public let queryParameters: [String: String]

    public init(pathParameters: [String: String] = [:], queryParameters: [String: String] = [:]) {
        self.pathParameters = pathParameters
        self.queryParameters = queryParameters
    }

    /// Retrieves a required path parameter, crashing with a precondition failure if absent.
    public func required(_ name: String) -> String {
        guard let value = pathParameters[name] ?? queryParameters[name] else {
            preconditionFailure("Missing required route parameter '\(name)'")
        }
        return value
    }

    /// Retrieves an optional path or query parameter.
    public func optional(_ name: String) -> String? {
        pathParameters[name] ?? queryParameters[name]
    }

    /// Retrieves a query parameter specifically.
    public func query(_ name: String) -> String? {
        queryParameters[name]
    }

    /// Subscript access.
    public subscript(name: String) -> String? {
        optional(name)
    }
}

/// Tokenized URL path pattern supporting static segments, parameters (`:id`), and wildcards (`*`).
public struct RoutePattern: Sendable, Equatable, Hashable {
    public enum Segment: Sendable, Equatable, Hashable {
        case literal(String)
        case parameter(String)
        case wildcard
    }

    public let rawPattern: String
    public let segments: [Segment]

    public init(_ pattern: String) {
        self.rawPattern = pattern
        let components = pattern.split(separator: "/", omittingEmptySubsequences: true)
        self.segments = components.map { comp -> Segment in
            let str = String(comp)
            if str.hasPrefix(":") {
                return .parameter(String(str.dropFirst()))
            } else if str == "*" {
                return .wildcard
            } else {
                return .literal(str)
            }
        }
    }

    /// Attempts to match a target path string, extracting dynamic path parameters on success.
    public func match(path: String) -> [String: String]? {
        let cleanPath = path.split(separator: "?").first.map(String.init) ?? path
        let pathComponents = cleanPath.split(separator: "/", omittingEmptySubsequences: true).map(String.init)

        // Wildcard pattern matches any prefix or complete path
        if segments.count == 1, case .wildcard = segments[0] {
            return [:]
        }

        guard segments.count == pathComponents.count else {
            // Check if last segment is wildcard
            if let last = segments.last, case .wildcard = last, pathComponents.count >= segments.count - 1 {
                var params: [String: String] = [:]
                for (idx, seg) in segments.dropLast().enumerated() {
                    switch seg {
                    case .literal(let lit):
                        if pathComponents[idx] != lit { return nil }
                    case .parameter(let name):
                        params[name] = pathComponents[idx]
                    case .wildcard:
                        break
                    }
                }
                return params
            }
            return nil
        }

        var params: [String: String] = [:]
        for (idx, seg) in segments.enumerated() {
            let component = pathComponents[idx]
            switch seg {
            case .literal(let lit):
                if lit != component { return nil }
            case .parameter(let name):
                params[name] = component
            case .wildcard:
                continue
            }
        }
        return params
    }
}

/// A route mapping a URL pattern to a Screen builder closure.
public struct Route: @unchecked Sendable {
    public let pattern: RoutePattern
    public let builder: @Sendable (RouteParameters) -> any Screen

    public init(_ pattern: String, builder: @escaping @Sendable (RouteParameters) -> any Screen) {
        self.pattern = RoutePattern(pattern)
        self.builder = builder
    }

    public init(_ pattern: RoutePattern, builder: @escaping @Sendable (RouteParameters) -> any Screen) {
        self.pattern = pattern
        self.builder = builder
    }
}

/// Central routing engine matching paths/URLs to declared routes and building target screens.
public final class Router: @unchecked Sendable {
    private let lock = NSLock()
    private var _routes: [Route]
    private var _notFoundHandler: (@Sendable (String) -> any Screen)?

    public init(
        routes: [Route] = [],
        notFoundHandler: (@Sendable (String) -> any Screen)? = nil
    ) {
        self._routes = routes
        self._notFoundHandler = notFoundHandler
    }

    /// Registers a new route in the router.
    public func register(_ route: Route) {
        lock.withLock {
            _routes.append(route)
        }
    }

    /// Sets the fallback screen builder when no routes match.
    public func setNotFoundHandler(_ handler: @escaping @Sendable (String) -> any Screen) {
        lock.withLock {
            _notFoundHandler = handler
        }
    }

    /// Resolves a path string into a Screen instance and its parameters.
    public func resolve(path: String) -> (screen: any Screen, parameters: RouteParameters)? {
        let (routes, notFound) = lock.withLock { (_routes, _notFoundHandler) }

        // Parse query items
        let queryParams = DeepLinkResolver.extractQueryParameters(from: path)

        for route in routes {
            if let pathParams = route.pattern.match(path: path) {
                let params = RouteParameters(pathParameters: pathParams, queryParameters: queryParams)
                let screen = route.builder(params)
                return (screen, params)
            }
        }

        if let notFound {
            let params = RouteParameters(pathParameters: [:], queryParameters: queryParams)
            return (notFound(path), params)
        }

        return nil
    }

    /// Resolves an incoming deep link URL into a Screen.
    public func resolve(url: URL) -> (screen: any Screen, parameters: RouteParameters)? {
        guard let path = DeepLinkResolver.path(from: url) else { return nil }
        return resolve(path: path)
    }
}

/// Pure parser translating custom schemes and universal links into internal route paths and parameters.
public enum DeepLinkResolver {
    /// Extracts a normalized route path from any supported URL (e.g. `prism://profile/42?tab=likes` or `https://app.example.com/profile/42`).
    public static func path(from url: URL) -> String? {
        var pathString = ""

        if let host = url.host, !host.isEmpty, url.scheme != "http", url.scheme != "https" {
            // Custom scheme: prism://profile/42 -> host is "profile", path is "/42"
            pathString = "/" + host + url.path
        } else {
            // Universal link: https://example.com/profile/42 -> path is "/profile/42"
            pathString = url.path.isEmpty ? "/" : url.path
        }

        if let query = url.query, !query.isEmpty {
            pathString += "?" + query
        }

        return normalizePath(pathString)
    }

    /// Extracts query parameters from a URL query string or path containing query items.
    public static func extractQueryParameters(from pathOrURL: String) -> [String: String] {
        guard let queryIndex = pathOrURL.firstIndex(of: "?") else { return [:] }
        let queryString = String(pathOrURL[pathOrURL.index(after: queryIndex)...])
        var params: [String: String] = [:]

        let pairs = queryString.split(separator: "&")
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard let key = parts.first.map(String.init)?.removingPercentEncoding else { continue }
            let value = parts.count > 1 ? (String(parts[1]).removingPercentEncoding ?? String(parts[1])) : ""
            params[key] = value
        }
        return params
    }

    /// Normalizes a route path by removing duplicate slashes, ensuring leading slash, and trimming trailing slashes.
    public static func normalizePath(_ path: String) -> String {
        let parts = path.split(separator: "?", maxSplits: 1)
        let rawPath = String(parts.first ?? "/")
        let query = parts.count > 1 ? "?" + parts[1] : ""

        let cleanComponents = rawPath.split(separator: "/", omittingEmptySubsequences: true)
        let normalized = "/" + cleanComponents.joined(separator: "/")
        return normalized + query
    }
}
