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
    @State private var isChoosingContact = false
    @State private var contact: CNContact?
    @State private var share: CKShare?
    @State private var loadingShare = false
    @State private var isSendingMessage = false
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
                    Button(action: { isChoosingContact = true }) { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $isChoosingContact, onDismiss: {
                Task {
                    guard let contact = contact else { return }
                    do {
                        loadingShare = true
                        (newChannel, share) = try await ChannelStore.addChannel(contact: contact)
                        loadingShare = false
                        isSendingMessage = true
                    } catch {
                        debugPrint("ERROR: Failed to create Channel: \(error)")
                    }
                    
                }
            }, content: {
                ContactPicker(contact: $contact)
            })
            .sheet(isPresented: $isSendingMessage, onDismiss: { [messageComposeResult] in
                contact = nil
                if let messageComposeResult = messageComposeResult {
                    if messageComposeResult == MessageComposeResult.sent, let newChannel = newChannel {
                        channels.append(newChannel)
                    }
                }
            }, content: { [loadingShare, contact, share] in
                if loadingShare {
                    ProgressView()
                } else if let contact = contact, let url = share?.url {
                    MessageComposeView(contact: contact, message: url.absoluteString, result: $messageComposeResult)
                }
            })
            .onChange(of: scenePhase) { phase in
                if phase == .inactive {
                    saveAction()
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView(channels: .constant(Channel.sampleData), saveAction: {})
        }
    }
}
