import SwiftUI
import Messages

struct CompactView: View {
    let cachedInvites: [EventPayload]
    let onExpand: () -> Void
    let onRSVP: (EventPayload, RSVPResponse) -> Void

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        Group {
            if cachedInvites.isEmpty {
                emptyView
            } else if cachedInvites.count == 1 {
                singleInviteView(cachedInvites[0])
            } else {
                multipleInvitesView
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var emptyView: some View {
        Button(action: onExpand) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.footnote)
                Text("Create Invite")
                    .font(.footnote)
            }
        }
    }

    private func singleInviteView(_ invite: EventPayload) -> some View {
        HStack(spacing: 6) {
            Button(action: onExpand) {
                Text(invite.title)
                    .font(.footnote)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    onRSVP(invite, .yes)
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.footnote)
                        .foregroundColor(.green)
                }

                Button {
                    onRSVP(invite, .maybe)
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.footnote)
                        .foregroundColor(.orange)
                }

                Button {
                    onRSVP(invite, .no)
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var multipleInvitesView: some View {
        let shown = Array(cachedInvites.prefix(3))
        let overflow = cachedInvites.count - 3

        return VStack(alignment: .leading, spacing: 2) {
            ForEach(shown) { invite in
                Button(action: onExpand) {
                    HStack(spacing: 4) {
                        Text(invite.title)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer()

                        Text(Self.dateFormatter.string(from: invite.startsAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }

            if overflow > 0 {
                Text("+\(overflow) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
