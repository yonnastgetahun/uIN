import SwiftUI

struct ClosedInviteView: View {

    let payload: EventPayload
    let onCreate: () -> Void

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

                // MARK: Title
                Text(payload.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .opacity(0.7)

                // MARK: Status Banner
                HStack(alignment: .top, spacing: 10) {
                    if payload.status == .closed {
                        Image(systemName: "xmark.seal")
                            .foregroundColor(.secondary)
                        Text("This event was closed by \(payload.hostName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(.secondary)
                        Text("This event has ended")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                )

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
                .foregroundColor(.secondary)
                .opacity(0.8)

                // MARK: Final RSVP Roster
                ClosedRosterSection(rsvps: payload.rsvps)

                Divider()

                // MARK: Create Your Own Invite
                Button(action: onCreate) {
                    Label("Create Your Own Invite", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

// MARK: - ClosedRosterSection

private struct ClosedRosterSection: View {
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
                ClosedRosterGroup(title: "Yes", count: yesNames.count, names: yesNames, color: .green)
            }
            if !maybeNames.isEmpty {
                ClosedRosterGroup(title: "Maybe", count: maybeNames.count, names: maybeNames, color: .orange)
            }
            if !noNames.isEmpty {
                ClosedRosterGroup(title: "No", count: noNames.count, names: noNames, color: .gray)
            }
        }
        .opacity(0.8)
    }
}

// MARK: - ClosedRosterGroup

private struct ClosedRosterGroup: View {
    let title: String
    let count: Int
    let names: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(title) (\(count))")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(color.opacity(0.8))
                .textCase(.uppercase)

            ForEach(names, id: \.self) { name in
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
