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
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(fetchRequest: Ledger.all, animation: .default) private var ledgers
    @State private var isChoosingContact = false
    @State private var contact: CNContact?
    @State private var newLedger: Ledger?
    @State private var share: CKShare?
    @State private var loadingShare = false
    @State private var isSendingMessage = false
    @State private var messageComposeResult: MessageComposeResult?
    
    var body: some View {
        List {
            ForEach(ledgers) { ledger in
                LedgerRowView(ledger: ledger)
            }
        }
        .navigationTitle("Heath")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isChoosingContact = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isChoosingContact, onDismiss: {
            guard contact != nil else { return }
            loadingShare = true
            isSendingMessage = true
            Task {
                await createLedger()
            }
            loadingShare = false
        }, content: {
            ContactPicker(contact: $contact)
        })
        .sheet(isPresented: $isSendingMessage, onDismiss: {
            guard let newLedger else { return }
            if messageComposeResult != .sent {
                context.delete(newLedger)
            }
            CoreDataStack.shared.save(with: .addLedger)
            contact = nil
        }, content: {
            if loadingShare {
                ProgressView("Creating Ledger")
            } else if let contact, let url = share?.url {
                MessageComposeView(contact: contact, message: url.absoluteString, result: $messageComposeResult)
            }
        })
    }
    
    private func createLedger() async {
        guard let contact else { return }
        newLedger = Ledger(context: context)
        guard let newLedger else { return }
        newLedger.createdAt = Date.now
        newLedger.contact = contact
        do {
            let (_, share, _) = try await CoreDataStack.shared.persistentContainer.share([newLedger], to: nil)
            guard let participant = await createShareParticipant(contact: contact) else { return }
            participant.permission = CKShare.ParticipantPermission.readWrite
            share.addParticipant(participant)
            share[CKShare.SystemFieldKey.title] = "Dylan and \(contact.givenName)"
            share[CKShare.SystemFieldKey.shareType] = "Ledger"
            self.share = try await CoreDataStack.shared.persistentContainer.persistUpdatedShare(share, in: CoreDataStack.shared.privatePersistentStore)
        } catch {
            debugPrint("ERROR: failed to create share: \(error)")
        }
    }
    
    private func createShareParticipant(contact: CNContact) async -> CKShare.Participant? {
        var lookupInfo: CKUserIdentity.LookupInfo?
        if contact.phoneNumbers.count > 0 {
            lookupInfo = CKUserIdentity.LookupInfo(phoneNumber: contact.phoneNumbers[0].value.stringValue)
        } else if contact.emailAddresses.count > 0 {
            lookupInfo = CKUserIdentity.LookupInfo(emailAddress: contact.emailAddresses[0].value as String)
        }
        guard let lookupInfo = lookupInfo else { return nil }
        let participants = await fetchParticipants(for: [lookupInfo])
        switch participants {
        case .success(let participants):
            debugPrint("Participants", participants)
            if !participants.isEmpty {
                debugPrint(participants[0].description)
                return participants[0]
            }
        case .failure(let error):
            debugPrint("ERROR: fetching CKShare.Participant failed: \(error)")
            return nil
        }
        return nil
    }
    
    private func fetchParticipants(for lookupInfos: [CKUserIdentity.LookupInfo]) async -> Result<[CKShare.Participant], Error> {
        await withCheckedContinuation { continuation in
            fetchParticipants(for: lookupInfos) { messages in
                continuation.resume(returning: messages)
            }
        }
    }
    
    private func fetchParticipants(for lookupInfos: [CKUserIdentity.LookupInfo],
                                   completion: @escaping (Result<[CKShare.Participant], Error>) -> Void) {
        var participants = [CKShare.Participant]()
        
        // Create the operation using the lookup objects
        // that the caller provides to the method.
        let operation = CKFetchShareParticipantsOperation(
            userIdentityLookupInfos: lookupInfos)
        
        // Collect the participants as CloudKit generates them.
        operation.perShareParticipantResultBlock = { _, result in
            switch result {
            case .success(let participant):
                participants.append(participant)
            case .failure(let error):
                debugPrint("ERROR: failed to fetch participant: \(error)")
            }
        }
        
        // If the operation fails, return the error to the caller.
        // Otherwise, return the array of participants.
        operation.fetchShareParticipantsResultBlock = { result in
            switch result {
            case .success():
                completion(.success(participants))
            case.failure(let error):
                debugPrint("ERROR: failed to fetch participant: \(error)")
                completion(.failure(error))
            }
        }
        
        // Set an appropriate QoS and add the operation to the
        // container's queue to execute it.
        operation.qualityOfService = .userInitiated
        CoreDataStack.shared.cloudKitContainer.add(operation)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView().environment(\.managedObjectContext, CoreDataStack.preview.persistentContainer.viewContext)
        }
    }
}
