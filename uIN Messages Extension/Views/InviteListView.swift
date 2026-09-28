import SwiftUI

struct InviteListView: View {
    let invites: [EventPayload]
    let onSelect: (EventPayload) -> Void
    let onCreate: () -> Void

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            Text("Tap an invite in the chat for the latest RSVPs")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            if invites.isEmpty {
                Spacer()
                Text("No active invites")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(invites.sorted { $0.startsAt < $1.startsAt }, id: \.eventID) { invite in
                            Button {
                                onSelect(invite)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(invite.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("Hosted by \(invite.hostName)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Text(Self.dateFormatter.string(from: invite.startsAt))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)

                                    let rsvpSummary = rsvpSummaryText(for: invite.rsvps)
                                    if !rsvpSummary.isEmpty {
                                        Text(rsvpSummary)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Button(action: onCreate) {
                Label("Create New Invite", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding()
            }
        }
    }

    private func rsvpSummaryText(for rsvps: [RSVP]) -> String {
        let yesCount = rsvps.filter { $0.response == .yes }.count
        let maybeCount = rsvps.filter { $0.response == .maybe }.count

        var parts: [String] = []
        if yesCount > 0 { parts.append("\(yesCount) Yes") }
        if maybeCount > 0 { parts.append("\(maybeCount) Maybe") }

        return parts.joined(separator: ", ")
    }
}
