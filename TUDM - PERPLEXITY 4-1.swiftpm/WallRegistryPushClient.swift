import Foundation
import Observation

/// Backend proxy response for a successful push.
struct WallRegistryPushResponse: Codable, Equatable {
    var ok: Bool
    var message: String
    var roomId: String?
    var wallId: String?
    var totalWidth: Double?
    var segmentCount: Int?
    var receivedAt: Date?
    var nextAction: String?
}

enum WallRegistryPushError: Error, LocalizedError {
    case endpointNotConfigured
    case invalidEndpoint(String)
    case notHTTPResponse
    case server(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .endpointNotConfigured:
            return "No backend endpoint is set. Add your proxy URL in the Wall Registry Push screen."
        case let .invalidEndpoint(raw):
            return "\"\(raw)\" is not a valid URL."
        case .notHTTPResponse:
            return "The server did not return an HTTP response."
        case let .server(statusCode, message):
            if let message, !message.isEmpty {
                return "Server rejected the push (\(statusCode)): \(message)"
            }
            return "Server returned status code \(statusCode)."
        }
    }
}

/// Endpoint + optional push token, persisted in UserDefaults so nothing is committed to Git.
///
/// The push token is only a shared secret for the proxy. The Perplexity API key lives
/// exclusively in the backend's environment and must never be stored here.
@Observable
final class WallRegistryPushSettings {
    static let endpointKey = "TUDM.WallRegistryPush.Endpoint"
    static let tokenKey = "TUDM.WallRegistryPush.Token"

    var endpointString: String
    var pushToken: String

    init() {
        self.endpointString = UserDefaults.standard.string(forKey: Self.endpointKey) ?? ""
        self.pushToken = UserDefaults.standard.string(forKey: Self.tokenKey) ?? ""
    }

    func save() {
        UserDefaults.standard.set(endpointString, forKey: Self.endpointKey)
        UserDefaults.standard.set(pushToken, forKey: Self.tokenKey)
    }

    func resolvedEndpoint() throws -> URL {
        let raw = endpointString.trimmed
        guard !raw.isEmpty else { throw WallRegistryPushError.endpointNotConfigured }
        guard let url = URL(string: raw), url.scheme != nil, url.host != nil else {
            throw WallRegistryPushError.invalidEndpoint(raw)
        }
        return url
    }
}

/// Validates a registry locally, then POSTs it to the backend proxy.
struct WallRegistryPushClient {
    private let endpoint: URL
    private let pushToken: String?
    private let urlSession: URLSession

    init(endpoint: URL, pushToken: String? = nil, urlSession: URLSession = .shared) {
        self.endpoint = endpoint
        self.pushToken = pushToken
        self.urlSession = urlSession
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // The proxy sends `new Date().toISOString()`, which includes milliseconds.
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let withFraction = try? Date(raw, strategy: .iso8601.time(includingFractionalSeconds: true)) {
                return withFraction
            }
            return try Date(raw, strategy: .iso8601)
        }
        return decoder
    }

    func validateAndPush(_ registry: WallRegistryEnvelope) async throws -> WallRegistryPushResponse {
        try registry.validate()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let pushToken, !pushToken.trimmed.isEmpty {
            request.setValue(pushToken.trimmed, forHTTPHeaderField: "X-Wall-Push-Token")
        }
        request.httpBody = try Self.makeEncoder().encode(registry)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw WallRegistryPushError.notHTTPResponse
        }

        let decoder = Self.makeDecoder()
        guard 200..<300 ~= http.statusCode else {
            let failure = try? decoder.decode(WallRegistryPushResponse.self, from: data)
            throw WallRegistryPushError.server(statusCode: http.statusCode, message: failure?.message)
        }
        return try decoder.decode(WallRegistryPushResponse.self, from: data)
    }
}
