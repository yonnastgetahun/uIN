import SwiftUI
import Messages

struct CreateInviteView: View {

    // MARK: - Init

    let conversation: MSConversation
    let onSend: (MSMessage, MSSession) -> Void
    var existingPayload: EventPayload? = nil

    // MARK: - State

    @State private var title = ""
    @State private var date = Date().addingTimeInterval(3600)
    @State private var locationName = ""
    @State private var note = ""
    @State private var showDuplicateAlert = false

    // MARK: - Computed

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && date > Date()
    }

    private var isEditing: Bool {
        existingPayload != nil
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section("Event Details") {
                TextField("Title", text: $title)

                DatePicker(
                    "Date & Time",
                    selection: $date,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )

                TextField("Location (optional)", text: $locationName)
                TextField("Note (optional)", text: $note)
            }

            Section {
                Button(isEditing ? "Update Invite" : "Send Invite") {
                    handleSend()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            if let payload = existingPayload {
                title = payload.title
                date = payload.startsAt
                locationName = payload.locationName ?? ""
                note = payload.note ?? ""
            }
        }
        .alert("You have an active invite", isPresented: $showDuplicateAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Create Another") {
                sendInvite()
            }
        } message: {
            Text("You already have an upcoming invite in this chat. Create another one?")
        }
    }

    // MARK: - Actions

    private func handleSend() {
        guard isValid else { return }

        if existingPayload == nil {
            let conversationID = conversation.localParticipantIdentifier.uuidString
            let hostID = conversation.localParticipantIdentifier.uuidString
            let activeInvites = CacheService.activeInvites(conversationID: conversationID)
            let hasDuplicate = activeInvites.contains { $0.hostID == hostID }

            if hasDuplicate {
                showDuplicateAlert = true
                return
            }
        }

        sendInvite()
    }

    private func sendInvite() {
        Task {
            let displayName = await ContactsService.displayName()

            let locationValue = locationName.trimmingCharacters(in: .whitespaces)
            let noteValue = note.trimmingCharacters(in: .whitespaces)

            let changeNote: String? = buildChangeNote()

            let payload = EventPayload(
                eventID: existingPayload?.eventID ?? UUID(),
                hostID: conversation.localParticipantIdentifier.uuidString,
                hostName: displayName,
                title: title.trimmingCharacters(in: .whitespaces),
                startsAt: date,
                locationName: locationValue.isEmpty ? nil : locationValue,
                note: noteValue.isEmpty ? nil : noteValue,
                status: .active,
                createdAt: existingPayload?.createdAt ?? Date(),
                updatedAt: Date(),
                changeNote: changeNote,
                rsvps: existingPayload?.rsvps ?? []
            )

            let session: MSSession = existingPayload != nil
                ? (MSSession())  // reuse pattern — MSSession is opaque; new session per send
                : MSSession()

            let message = MessageComposer.compose(payload: payload, session: session)

            let conversationID = conversation.localParticipantIdentifier.uuidString
            CacheService.cache(payload: payload, conversationID: conversationID)

            onSend(message, session)
        }
    }

    // MARK: - Change Note

    private func buildChangeNote() -> String? {
        guard let old = existingPayload else { return nil }

        var changes: [String] = []

        let oldTitle = old.title
        let newTitle = title.trimmingCharacters(in: .whitespaces)
        if oldTitle != newTitle {
            changes.append("Renamed to \"\(newTitle)\"")
        }

        if !Calendar.current.isDate(old.startsAt, equalTo: date, toGranularity: .minute) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none

            let sameDay = Calendar.current.isDate(old.startsAt, inSameDayAs: date)
            if sameDay {
                changes.append("Time moved to \(timeFormatter.string(from: date))")
            } else {
                changes.append("Date changed to \(dateFormatter.string(from: date)) at \(timeFormatter.string(from: date))")
            }
        }

        let oldLocation = old.locationName ?? ""
        let newLocation = locationName.trimmingCharacters(in: .whitespaces)
        if oldLocation != newLocation {
            if newLocation.isEmpty {
                changes.append("Location removed")
            } else if oldLocation.isEmpty {
                changes.append("New spot: \(newLocation)")
            } else {
                changes.append("New spot: \(newLocation)")
            }
        }

        let oldNote = old.note ?? ""
        let newNote = note.trimmingCharacters(in: .whitespaces)
        if oldNote != newNote {
            if newNote.isEmpty {
                changes.append("Note removed")
            } else {
                changes.append("Note updated")
            }
        }

        guard !changes.isEmpty else { return nil }
        return changes.joined(separator: " · ")
    }
}
