//
//  Transaction.swift
//  Heath
//
//  Created by Dylan Hu on 11/6/22.
//

import Foundation
import CloudKit

struct Transaction: Identifiable {
    let id: UUID
    let amount: Double
    let split: Double
    let date: Date?
    let associatedRecord: CKRecord
}

extension Transaction {
    /// Initializes a `Transaction` object from a CloudKit record.
    /// - Parameter record: CloudKit record to pull values from.
    init?(record: CKRecord) {
        guard let amount = record["amount"] as? Double,
              let split = record["split"] as? Double else {
            return nil
        }

        self.id = UUID()
        self.amount = amount
        self.split = split
        self.date = record.creationDate
        self.associatedRecord = record
    }
}
