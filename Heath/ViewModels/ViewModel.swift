//
//  ViewModel.swift
//  Heath
//
//  Created by Dylan Hu on 11/9/22.
//  Based on https://github.com/apple/sample-cloudkit-zonesharing

import Foundation
import CloudKit
import OSLog

@MainActor
final class ViewModel: ObservableObject {

    // MARK: - Error

    enum ViewModelError: Error {
        case invalidRemoteShare
    }

    // MARK: - State

    enum State {
        case loading
        case loaded(privateChannels: [Channel], sharedChannels: [Channel])
        case error(Error)
    }

    // MARK: - Properties

    /// State directly observable by our view.
    @Published private(set) var state: State = .loading
    /// Use the specified iCloud container ID, which should also be present in the entitlements file.
    lazy var container = CKContainer(identifier: Config.containerIdentifier)
    /// This project uses the user's private database.
    private lazy var database = container.privateCloudDatabase

    // MARK: - Init

    nonisolated init() {}

    /// Initializer to provide explicit state (e.g. for previews).
    init(state: State) {
        self.state = state
    }

    // MARK: - API

    /// Fetches channels from the remote databases and updates local state.
    func refresh() async throws {
        state = .loading
        do {
            let (privateChannels, sharedChannels) = try await fetchPrivateAndSharedChannels()
            state = .loaded(privateChannels: privateChannels, sharedChannels: sharedChannels)
        } catch {
            state = .error(error)
        }
    }
    
    /// Fetches both private and shared channels in parallel.
    /// - Returns: A tuple containing separated private and shared channels.
    func fetchPrivateAndSharedChannels() async throws -> (private: [Channel], shared: [Channel]) {
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
    ///   - channel: Name of the `Channel` the `Transaction` should belong to.
    func addChannel(channel: String) async throws -> Channel {
        do {
            let zone = CKRecordZone(zoneName: channel)
            try await database.save(zone)
            return Channel(zone: zone, transactions: [])
        } catch {
            debugPrint("ERROR: Failed to create new Channel: \(error)")
            throw error
        }
    }

    /// Adds a new Transaction to the database.
    /// - Parameters:
    ///   - amount: Amount of the `Transaction`.
    ///   - split: Proportion of amount channel owner paid.
    ///   - channel: Name of the `Channel` the `Transaction` should belong to.
    func addTransaction(amount: Double, split: Double, channel: String) async throws {
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
    ///   - completionHandler: Handler to process a `success` or `failure` result.
    func fetchOrCreateShare(channel: Channel) async throws -> (CKShare, CKContainer) {
        guard let existingShare = channel.zone.share else {
            let share = CKShare(recordZoneID: channel.zone.zoneID)
            share[CKShare.SystemFieldKey.title] = "Heath: \(channel.name)"
            let (saveResults, _) = try await database.modifyRecords(saving: [share], deleting: [])
            debugPrint(saveResults)
            return (share, container)
        }

        guard let share = try await database.record(for: existingShare.recordID) as? CKShare else {
            throw ViewModelError.invalidRemoteShare
        }

        return (share, container)
    }

    // MARK: - Private

    /// Fetches `Channel`s for a given set of zones in a given database scope.
    /// - Parameters:
    ///   - scope: Database scope to fetch from.
    ///   - zones: Record zones to fetch `Channel`s from.
    /// - Returns: An array of `Channel`s (a zone name and an array of `Transaction` objects).
    private func fetchChannels(
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
                allChannels.append(Channel(zone: zone, transactions: transactionsResult))
            }
        }

        return allChannels
    }
}
