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
    @EnvironmentObject private var vm: ViewModel
    @State private var isAddingContact = false
    @State private var contact: CNContact?
    @State private var share: CKShare?
    @State private var loadingShare = false
    @State private var isSharing = false
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.purple]
    }
    
    var body: some View {
        List {
            /// TODO: map list of channels to `ChannelRowView`s
        }
        .navigationTitle("Heath")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { Task {
                    try await vm.refresh()
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
            let newChannel = try await vm.addChannel(channel: contact.identifier)
            isSharing = true
            loadingShare = true
            let (newShare, _) = try await vm.fetchOrCreateShare(channel: newChannel)
            loadingShare = false
            share = newShare
        } catch {
            debugPrint("ERROR: Failed to create Channel: \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
        }
    }
}
