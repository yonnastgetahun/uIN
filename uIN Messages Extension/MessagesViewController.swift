//
//  MessagesViewController.swift
//  uIN Messages Extension
//
//  Created by YonnasCore on 4/23/26.
//

import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {

    // MARK: - Properties

    var currentSession: MSSession?
    var currentConversationID: String?

    // MARK: - Lifecycle

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)

        currentConversationID = conversation.localParticipantIdentifier.uuidString

        // In transcript context we have no interactive UI to show
        guard presentationStyle != .transcript else { return }

        // If the user tapped a message bubble, decode and route to it
        if let message = conversation.selectedMessage, let url = message.url {
            currentSession = message.session
            if let payload = PayloadCoder.decode(url) {
                if payload.status == .closed || payload.startsAt < Date() {
                    showClosedView(payload: payload)
                } else {
                    showDetailView(payload: payload, conversation: conversation)
                }
            }
            return
        }

        // No selected message — check the cache for active invites in this conversation
        let invites = CacheService.activeInvites(conversationID: currentConversationID ?? "")
        if invites.count > 0 {
            showListView(invites: invites, conversation: conversation)
        } else {
            showCreateView(conversation: conversation)
        }
    }

    // MARK: - Message Selection

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        guard let url = message.url, let payload = PayloadCoder.decode(url) else { return }

        currentSession = message.session

        if payload.status == .closed || payload.startsAt < Date() {
            showClosedView(payload: payload)
        } else {
            showDetailView(payload: payload, conversation: conversation)
        }

        requestPresentationStyle(.expanded)
    }

    // MARK: - Presentation Style Transitions

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        guard let conversation = activeConversation else { return }

        if presentationStyle == .compact {
            let invites = CacheService.activeInvites(conversationID: currentConversationID ?? "")
            presentChild(CompactView(
                cachedInvites: invites,
                onExpand: { [weak self] in
                    self?.requestPresentationStyle(.expanded)
                },
                onRSVP: { [weak self] invite, response in
                    Task {
                        let name = await ContactsService.displayName()
                        var updated = invite
                        let myID = conversation.localParticipantIdentifier.uuidString
                        if let idx = updated.rsvps.firstIndex(where: { $0.participantID == myID }) {
                            updated.rsvps[idx].response = response
                            updated.rsvps[idx].respondedAt = Date()
                            updated.rsvps[idx].name = name
                        } else {
                            updated.rsvps.append(RSVP(participantID: myID, name: name, response: response, respondedAt: Date()))
                        }
                        let session = self?.currentSession ?? MSSession()
                        let message = MessageComposer.compose(payload: updated, session: session)
                        conversation.insert(message) { _ in }
                        CacheService.cache(payload: updated, conversationID: myID)
                    }
                }
            ))
        } else {
            // Re-route for expanded
            let invites = CacheService.activeInvites(conversationID: currentConversationID ?? "")
            if invites.count > 0 {
                showListView(invites: invites, conversation: conversation)
            } else {
                showCreateView(conversation: conversation)
            }
        }
    }

    // MARK: - Child View Presenter

    private func presentChild<V: View>(_ view: V) {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        let host = UIHostingController(rootView: view)
        addChild(host)
        host.view.frame = self.view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    // MARK: - Routing

    private func showCreateView(conversation: MSConversation) {
        presentChild(CreateInviteView(conversation: conversation, onSend: { [weak self] message, session in
            self?.currentSession = session
            conversation.insert(message) { _ in }
            // Collapse to compact so the user sees the bubble ready to send
            self?.requestPresentationStyle(.compact)
        }))
    }

    private func showEditView(payload: EventPayload, conversation: MSConversation) {
        presentChild(CreateInviteView(conversation: conversation, onSend: { [weak self] message, session in
            self?.currentSession = session
            conversation.insert(message) { _ in }
            self?.requestPresentationStyle(.compact)
        }, existingPayload: payload))
    }

    private func showDetailView(payload: EventPayload, conversation: MSConversation) {
        let session = currentSession ?? MSSession()
        presentChild(InviteDetailView(
            payload: payload,
            conversation: conversation,
            session: session,
            onUpdate: { message in
                conversation.insert(message) { _ in }
            },
            onEdit: { [weak self] in
                self?.showEditView(payload: payload, conversation: conversation)
            },
            onClose: { [weak self] in
                var closed = payload
                closed.status = .closed
                closed.updatedAt = Date()
                let msg = MessageComposer.compose(payload: closed, session: session)
                conversation.insert(msg) { _ in }
                let convID = conversation.localParticipantIdentifier.uuidString
                CacheService.cache(payload: closed, conversationID: convID)
                self?.showClosedView(payload: closed)
            }
        ))
    }

    private func showListView(invites: [EventPayload], conversation: MSConversation) {
        presentChild(InviteListView(
            invites: invites,
            onSelect: { [weak self] invite in
                self?.showDetailView(payload: invite, conversation: conversation)
                self?.requestPresentationStyle(.expanded)
            },
            onCreate: { [weak self] in
                self?.showCreateView(conversation: conversation)
                self?.requestPresentationStyle(.expanded)
            }
        ))
    }

    private func showClosedView(payload: EventPayload) {
        presentChild(ClosedInviteView(payload: payload, onCreate: { [weak self] in
            guard let conversation = self?.activeConversation else { return }
            self?.showCreateView(conversation: conversation)
        }))
    }

    private func showNonIMessageView() {
        presentChild(NonIMessageView())
    }
}
