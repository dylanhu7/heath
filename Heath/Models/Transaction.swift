//
//  Transaction.swift
//  Heath
//
//  Created by Dylan Hu on 11/6/22.
//

import Foundation
import CloudKit

struct Transaction: Identifiable, Codable {
    let id: String
    let amount: Double
    let split: Double
    let date: Date?
}

extension Transaction {
    /// Initializes a `Transaction` object from a CloudKit record.
    /// - Parameter record: CloudKit record to pull values from.
    init?(record: CKRecord) {
        guard let amount = record["amount"] as? Double,
              let split = record["split"] as? Double else {
            return nil
        }

        self.id = record.recordID.recordName
        self.amount = amount
        self.split = split
        self.date = record.creationDate
    }
}
