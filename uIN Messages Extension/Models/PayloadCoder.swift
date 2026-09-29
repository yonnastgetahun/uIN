import Foundation

enum PayloadCoder {
    static func encode(_ payload: EventPayload) -> URL? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return nil }
        let base64 = data.base64EncodedString()
        // Use a proper URL scheme that iMessage preserves across devices
        var components = URLComponents()
        components.scheme = "https"
        components.host = "useuin.com"
        components.path = "/invite"
        components.queryItems = [URLQueryItem(name: "d", value: base64)]
        return components.url
    }

    static func decode(_ url: URL) -> EventPayload? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let base64 = components.queryItems?.first(where: { $0.name == "d" })?.value,
              let data = Data(base64Encoded: base64) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(EventPayload.self, from: data)
    }
}
