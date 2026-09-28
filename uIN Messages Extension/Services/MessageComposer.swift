import Foundation
import Messages

enum MessageComposer {

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    static func compose(payload: EventPayload, session: MSSession?) -> MSMessage {
        let layout = MSMessageTemplateLayout()

        // caption/subcaption are the primary visible text fields in a bubble without an image
        layout.caption = payload.title
        layout.subcaption = payload.locationName ?? dateFormatter.string(from: payload.startsAt)

        // trailing fields for RSVP counts
        let yesCount = payload.rsvps.filter { $0.response == .yes }.count
        let maybeCount = payload.rsvps.filter { $0.response == .maybe }.count

        layout.trailingCaption = dateFormatter.string(from: payload.startsAt) + " " + timeFormatter.string(from: payload.startsAt)

        var rsvpParts: [String] = []
        if yesCount > 0 { rsvpParts.append("\(yesCount) Yes") }
        if maybeCount > 0 { rsvpParts.append("\(maybeCount) Maybe") }
        layout.trailingSubcaption = rsvpParts.isEmpty ? nil : rsvpParts.joined(separator: " · ")

        let message = MSMessage(session: session ?? MSSession())
        message.layout = layout
        message.url = PayloadCoder.encode(payload)
        message.summaryText = "RSVP: \(payload.title)"

        return message
    }
}
