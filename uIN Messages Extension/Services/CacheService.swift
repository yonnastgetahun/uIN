import Foundation

enum CacheService {

    private static let appGroupID = "group.com.yonnasgetahun.uin"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private static func key(for conversationID: String) -> String {
        "conversation_\(conversationID)"
    }

    private static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: - Private Helpers

    private static func load(conversationID: String) -> [EventPayload] {
        let k = key(for: conversationID)
        guard let data = defaults?.data(forKey: k) else { return [] }
        return (try? decoder.decode([EventPayload].self, from: data)) ?? []
    }

    private static func save(_ payloads: [EventPayload], conversationID: String) {
        guard let data = try? encoder.encode(payloads) else { return }
        defaults?.set(data, forKey: key(for: conversationID))
    }

    // MARK: - Public API

    static func cache(payload: EventPayload, conversationID: String) {
        var payloads = load(conversationID: conversationID)
        if let index = payloads.firstIndex(where: { $0.eventID == payload.eventID }) {
            payloads[index] = payload
        } else {
            payloads.append(payload)
        }
        save(payloads, conversationID: conversationID)
    }

    static func activeInvites(conversationID: String) -> [EventPayload] {
        let now = Date()
        return load(conversationID: conversationID).filter {
            $0.status == .active && $0.startsAt > now
        }
    }

    static func clearExpired(conversationID: String) {
        let now = Date()
        let kept = load(conversationID: conversationID).filter {
            $0.status == .active && $0.startsAt > now
        }
        save(kept, conversationID: conversationID)
    }
}
