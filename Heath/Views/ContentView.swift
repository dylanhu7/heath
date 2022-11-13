//
//  ContentView.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import SwiftUI
import Contacts
import CloudKit

struct ContentView: View {
    @Binding var channels: [Channel]
    @State private var isAddingContact = false
    @State private var contact: CNContact?
    @State private var share: CKShare?
    @State private var loadingShare = false
    @State private var isSharing = false
    
    var body: some View {
        List {
            /// TODO: map list of channels to `ChannelRowView`s
        }
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
        .sheet(isPresented: $isSharing) { [loadingShare, contact, share] in
            if loadingShare {
                ProgressView()
            } else if let contact1 = contact, let url = share?.url {
                MessageComposeView(contact: contact1, message: url.absoluteString)
            }
        }
    }
    
    private func createChannel() async {
        guard let contact = contact else { return }
        do {
            let newChannel = try await ChannelStore.addChannel(id: contact.identifier)
            isSharing = true
            loadingShare = true
            let (newShare, _) = try await ChannelStore.fetchOrCreateShare(channel: newChannel)
            loadingShare = false
            share = newShare
        } catch {
            debugPrint("ERROR: Failed to create Channel: \(error)")
        }
    }
}
