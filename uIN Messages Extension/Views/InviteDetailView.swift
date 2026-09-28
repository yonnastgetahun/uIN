import SwiftUI
import Messages

struct InviteDetailView: View {

    let payload: EventPayload
    let conversation: MSConversation
    let session: MSSession
    let onUpdate: (MSMessage) -> Void
    let onEdit: (() -> Void)?
    let onClose: (() -> Void)?

    // MARK: - Computed

    var myID: String {
        conversation.localParticipantIdentifier.uuidString
    }

    var isHost: Bool {
        payload.hostID == myID
    }

    var myResponse: RSVPResponse? {
        payload.rsvps.first(where: { $0.participantID == myID })?.response
    }

    // MARK: - Formatters

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.title)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Hosted by \(payload.hostName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // MARK: Change Note Banner
                if let changeNote = payload.changeNote, !changeNote.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text(changeNote)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.12))
                    )
                }

                // MARK: Details
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        Self.dateFormatter.string(from: payload.startsAt),
                        systemImage: "calendar"
                    )
                    Label(
                        Self.timeFormatter.string(from: payload.startsAt),
                        systemImage: "clock"
                    )
                    if let location = payload.locationName, !location.isEmpty {
                        Label(location, systemImage: "mappin")
                    }
                    if let note = payload.note, !note.isEmpty {
                        Label(note, systemImage: "note.text")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.primary)

                // MARK: RSVP Buttons
                if payload.status == .active {
                    HStack(spacing: 24) {
                        RSVPButton(
                            label: "Yes",
                            filledSymbol: "checkmark.circle.fill",
                            emptySymbol: "checkmark.circle",
                            tint: .green,
                            isSelected: myResponse == .yes
                        ) {
                            submitRSVP(.yes)
                        }

                        RSVPButton(
                            label: "Maybe",
                            filledSymbol: "questionmark.circle.fill",
                            emptySymbol: "questionmark.circle",
                            tint: .orange,
                            isSelected: myResponse == .maybe
                        ) {
                            submitRSVP(.maybe)
                        }

                        RSVPButton(
                            label: "No",
                            filledSymbol: "xmark.circle.fill",
                            emptySymbol: "xmark.circle",
                            tint: .gray,
                            isSelected: myResponse == .no
                        ) {
                            submitRSVP(.no)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // MARK: Roster
                RosterSection(rsvps: payload.rsvps)

                // MARK: Host Controls
                if isHost {
                    VStack(spacing: 12) {
                        if let onEdit {
                            Button(action: onEdit) {
                                Label("Edit Event", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)
                        }

                        if let onClose {
                            Button(role: .destructive, action: onClose) {
                                Label("Close Event", systemImage: "xmark.seal")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - RSVP Action

    private func submitRSVP(_ response: RSVPResponse) {
        Task {
            let displayName = await ContactsService.displayName()

            var updated = payload
            if let index = updated.rsvps.firstIndex(where: { $0.participantID == myID }) {
                updated.rsvps[index].response = response
                updated.rsvps[index].respondedAt = Date()
                updated.rsvps[index].name = displayName
            } else {
                let rsvp = RSVP(
                    participantID: myID,
                    name: displayName,
                    response: response,
                    respondedAt: Date()
                )
                updated.rsvps.append(rsvp)
            }

            let message = MessageComposer.compose(payload: updated, session: session)
            onUpdate(message)

            let conversationID = conversation.localParticipantIdentifier.uuidString
            CacheService.cache(payload: updated, conversationID: conversationID)
        }
    }
}

// MARK: - RSVPButton

private struct RSVPButton: View {
    let label: String
    let filledSymbol: String
    let emptySymbol: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? filledSymbol : emptySymbol)
                    .font(.title2)
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? tint : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RosterSection

private struct RosterSection: View {
    let rsvps: [RSVP]

    private var yesNames: [String] {
        rsvps.filter { $0.response == .yes }.map { $0.name }
    }

    private var maybeNames: [String] {
        rsvps.filter { $0.response == .maybe }.map { $0.name }
    }

    private var noNames: [String] {
        rsvps.filter { $0.response == .no }.map { $0.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !yesNames.isEmpty {
                RosterGroup(title: "Yes", count: yesNames.count, names: yesNames, color: .green)
            }
            if !maybeNames.isEmpty {
                RosterGroup(title: "Maybe", count: maybeNames.count, names: maybeNames, color: .orange)
            }
            if !noNames.isEmpty {
                RosterGroup(title: "No", count: noNames.count, names: noNames, color: .gray)
            }
        }
    }
}

// MARK: - RosterGroup

private struct RosterGroup: View {
    let title: String
    let count: Int
    let names: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(title) (\(count))")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .textCase(.uppercase)

            ForEach(names, id: \.self) { name in
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
    }
}
