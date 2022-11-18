//
//  ChannelStore.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI
import CloudKit
import Contacts

class ChannelStore: ObservableObject {
    enum ChannelStoreError: Error {
        case invalidRemoteShare
        case participantNotFound
        case createShareFailure
    }
    
    @Published var channels: [Channel] = []
    /// Use the specified iCloud container ID, which should also be present in the entitlements file.
    static var container = CKContainer(identifier: Config.containerIdentifier)
    /// This project uses the user's private database.
    static private var database = container.privateCloudDatabase
    static var contactStore = CNContactStore()
    
    /// Fetches channels from the remote databases and updates local state.
    static func refresh() async throws -> [Channel] {
        let (privateChannels, sharedChannels) = try await fetchPrivateAndSharedChannels()
        // TODO: sort by unshared and by recency
        return privateChannels + sharedChannels
    }
    
    /// Fetches both private and shared channels in parallel.
    /// - Returns: A tuple containing separated private and shared channels.
    static func fetchPrivateAndSharedChannels() async throws -> (private: [Channel], shared: [Channel]) {
        // Determine zones for each channel.
        // In the Private DB, we want to ignore the default zone.
        let privateZones = try await database.allRecordZones()
            .filter { $0.zoneID != CKRecordZone.default().zoneID }
        let sharedZones = try await container.sharedCloudDatabase.allRecordZones()
        
        // This will run each of these operations in parallel.
        async let privateChannels = fetchChannels(scope: .private, in: privateZones)
        async let sharedChannels = fetchChannels(scope: .shared, in: sharedZones)
        
        return (private: try await privateChannels, shared: try await sharedChannels)
    }
    
    /// Adds a new Channel to the database.
    /// - Parameters:
    ///   - id: Identifier of the contact the `Channel` will be shared with.
    static func addChannel(contact: CNContact) async throws -> (Channel, CKShare) {
        guard let participant = await createShareParticipant(contact: contact) else {
            debugPrint("ERROR: Did not find participant")
            throw ChannelStoreError.participantNotFound
        }
        guard let userRecordName = participant.userIdentity.userRecordID?.recordName else {
            debugPrint("ERROR: Found participant does not have user record")
            throw ChannelStoreError.participantNotFound
        }
        let zone = CKRecordZone(zoneName: userRecordName)
        do {
            try await database.save(zone)
        } catch {
            debugPrint("ERROR: Failed to create new Channel: \(error)")
            throw error
        }
        let channel = Channel(from: zone)
        var share: CKShare
        do {
            share = try await fetchOrCreateShare(channel: channel, participant: participant)
        } catch {
            debugPrint("ERROR: Failed to create new CKShare: \(error)")
            throw ChannelStoreError.createShareFailure
        }
        return (channel, share)
    }
    
    /// Adds a new Transaction to the database.
    /// - Parameters:
    ///   - amount: Amount of the `Transaction`.
    ///   - split: Proportion of amount channel owner paid.
    ///   - channel: Name of the `Channel` the `Transaction` should belong to.
    static func addTransaction(amount: Double, split: Double, channel: String) async throws {
        do {
            // Ensure zone exists first.
            let zone = CKRecordZone(zoneName: channel)
            try await database.save(zone)
            let id = CKRecord.ID(zoneID: zone.zoneID)
            let transactionRecord = CKRecord(recordType: "Transaction", recordID: id)
            transactionRecord["amount"] = amount
            transactionRecord["split"] = split
            try await database.save(transactionRecord)
        } catch {
            debugPrint("ERROR: Failed to save new Transaction: \(error)")
            throw error
        }
    }
    
    /// Fetches an existing `CKShare` on a channel zone, or creates a new one in preparation to share with another user.
    /// - Parameters:
    ///   - channel: `Channel` to share.
    static func fetchOrCreateShare(channel: Channel, participant: CKShare.Participant) async throws -> CKShare {
        let zoneID = CKRecordZone.ID(__zoneName: channel.id, ownerName: channel.ownerName)
        let zone = try await database.recordZone(for: zoneID)
        let share = CKShare(recordZoneID: zone.zoneID)
        share.addParticipant(participant)
        share[CKShare.SystemFieldKey.title] = "Heath: \(channel.name)"
        let (saveResults, _) = try await database.modifyRecords(saving: [share], deleting: [])
        debugPrint(saveResults)
        return share
    }
    
    /// Fetches `Channel`s for a given set of zones in a given database scope.
    /// - Parameters:
    ///   - scope: Database scope to fetch from.
    ///   - zones: Record zones to fetch `Channel`s from.
    /// - Returns: An array of `Channel`s (a zone name and an array of `Transaction` objects).
    static private func fetchChannels(
        scope: CKDatabase.Scope,
        in zones: [CKRecordZone]
    ) async throws -> [Channel] {
        guard !zones.isEmpty else {
            return []
        }
        
        let database = container.database(with: scope)
        var allChannels: [Channel] = []
        
        // Inner function retrieving and converting all Transaction records for a single zone.
        @Sendable func transactionsInZone(_ zone: CKRecordZone) async throws -> [Transaction] {
            if zone.zoneID == CKRecordZone.default().zoneID {
                return []
            }
            
            var allTransactions: [Transaction] = []
            
            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil
            
            while awaitingChanges {
                let zoneChanges = try await database.recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
                let transactions = zoneChanges.modificationResultsByID.values
                    .compactMap { try? $0.get().record }
                    .compactMap { Transaction(record: $0) }
                allTransactions.append(contentsOf: transactions)
                
                awaitingChanges = zoneChanges.moreComing
                nextChangeToken = zoneChanges.changeToken
            }
            
            return allTransactions
        }
        
        // Using this task group, fetch each zone's transactions in parallel.
        try await withThrowingTaskGroup(of: (CKRecordZone, [Transaction]).self) { group in
            for zone in zones {
                group.addTask {
                    (zone, try await transactionsInZone(zone))
                }
            }
            
            // As each result comes back, append it to a combined array to finally return.
            for try await (zone, transactionsResult) in group {
                allChannels.append(Channel(from: zone, with: transactionsResult))
            }
        }
        
        return allChannels
    }
    
    private static func createShareParticipant(contact: CNContact) async -> CKShare.Participant? {
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
    
    private static func fetchParticipants(for lookupInfos: [CKUserIdentity.LookupInfo]) async -> Result<[CKShare.Participant], Error> {
        await withCheckedContinuation { continuation in
            fetchParticipants(for: lookupInfos) { messages in
                continuation.resume(returning: messages)
            }
        }
    }
    
    private static func fetchParticipants(for lookupInfos: [CKUserIdentity.LookupInfo],
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
        container.add(operation)
    }
    
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("channels.data")
    }
    
    static func load() async throws -> [Channel] {
        try await withCheckedThrowingContinuation { continuation in
            load { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let channels):
                    continuation.resume(returning: channels)
                }
            }
        }
    }
    
    static func load(completion: @escaping (Result<[Channel], Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try fileURL()
                guard let file = try? FileHandle(forReadingFrom: fileURL) else {
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                let decodedChannels = try JSONDecoder().decode([Channel].self, from: file.availableData)
                let decodedChannelsWithContacts = decodedChannels.map {
                    syncChannelWithContacts(channel: $0)
                }
                DispatchQueue.main.async {
                    completion(.success(decodedChannelsWithContacts))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    @discardableResult
    static func save(channels: [Channel]) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            save(channels: channels) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let channelsSaved):
                    continuation.resume(returning: channelsSaved)
                }
            }
        }
    }
    
    static func save(channels: [Channel], completion: @escaping (Result<Int, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(channels)
                let outfile = try fileURL()
                try data.write(to: outfile)
                DispatchQueue.main.async {
                    completion(.success(channels.count))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func syncChannelWithContacts(channel: Channel) -> Channel {
        var newChannel = Channel(name: channel.name, id: channel.id, ownerName: channel.ownerName, transactions: channel.transactions)
        do {
            newChannel.contact = try contactStore.unifiedContact(withIdentifier: channel.id, keysToFetch: Channel.keysToFetch)
        } catch {
            debugPrint("ERROR: could not find contact for id \(channel.id)")
        }
        return channel
    }
}
