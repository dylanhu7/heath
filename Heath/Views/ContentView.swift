//
//  ContentView.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import SwiftUI
import Contacts
import CloudKit
import MessageUI

struct ContentView: View {
    @Binding var channels: [Channel]
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAddingContact = false
    @State private var contact: CNContact?
    @State private var share: CKShare?
    @State private var loadingShare = false
    @State private var isSharing = false
    @State private var newChannel: Channel?
    @State private var messageComposeResult: MessageComposeResult?
    let saveAction: () -> Void
    
    var body: some View {
        ChannelsListView(channels: $channels)
            .navigationTitle("Heath")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { Task {
                        channels = try await ChannelStore.refresh()
                    } } label: { Image(systemName: "arrow.clockwise") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingContact = true }) { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $isAddingContact, onDismiss: {
                Task {
                    await createChannel()
                }
            }) {
                ContactPicker(contact: $contact)
            }
            .sheet(isPresented: $isSharing, onDismiss: { [messageComposeResult] in
                if let messageComposeResult = messageComposeResult {
                    debugPrint(messageComposeResult.rawValue)
                    if messageComposeResult == MessageComposeResult.sent, let newChannel = newChannel {
                        channels.append(newChannel)
                        debugPrint(channels)
                    }
                }
            }) { [loadingShare, contact, share] in
                if loadingShare {
                    ProgressView()
                } else if let contact1 = contact, let url = share?.url {
                    MessageComposeView(contact: contact1, message: url.absoluteString, result: $messageComposeResult)
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .inactive {
                    saveAction()
                }
            }
    }
    
    private func createChannel() async {
        guard let contact = contact else { return }
        do {
            newChannel = try await ChannelStore.addChannel(id: contact.identifier)
            isSharing = true
            loadingShare = true
            if let newChannel = newChannel {
                let (newShare, _) = try await ChannelStore.fetchOrCreateShare(channel: newChannel, contact: contact)
                share = newShare
            }
            loadingShare = false
        } catch {
            debugPrint("ERROR: Failed to create Channel: \(error)")
        }
    }
}
