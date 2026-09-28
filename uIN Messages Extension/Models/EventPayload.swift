import Foundation

enum EventStatus: String, Codable {
    case active
    case closed
}

enum RSVPResponse: String, Codable {
    case yes
    case maybe
    case no
}

struct RSVP: Codable {
    let participantID: String
    var name: String
    var response: RSVPResponse
    var respondedAt: Date

    enum CodingKeys: String, CodingKey {
        case participantID = "p"
        case name = "n"
        case response = "r"
        case respondedAt = "ra"
    }
}

struct EventPayload: Codable, Identifiable {
    var id: UUID { eventID }
    let eventID: UUID
    let hostID: String
    let hostName: String
    let title: String
    let startsAt: Date
    var locationName: String?
    var note: String?
    var status: EventStatus
    let createdAt: Date
    var updatedAt: Date
    var changeNote: String?
    var rsvps: [RSVP]

    enum CodingKeys: String, CodingKey {
        case eventID = "i"
        case hostID = "h"
        case hostName = "hn"
        case title = "t"
        case startsAt = "s"
        case locationName = "l"
        case note = "n"
        case status = "st"
        case createdAt = "ca"
        case updatedAt = "ua"
        case changeNote = "cn"
        case rsvps = "r"
    }
}
