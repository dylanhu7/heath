//
//  Transaction.swift
//  Heath
//
//  Created by Dylan Hu on 11/6/22.
//

import CloudKit

struct Transaction: Identifiable, Codable {
    let id: String
    let description: String
    let amount: Double
    let split: Double
    let date: Date?
    
    init(id: String, description: String, amount: Double, split: Double, date: Date) {
        self.id = id
        self.description = description
        self.amount = amount
        self.split = split
        self.date = date
    }
    
    /// Initializes a `Transaction` object from a CloudKit record.
    /// - Parameter record: CloudKit record to pull values from.
    init?(record: CKRecord) {
        guard let amount = record["amount"] as? Double,
              let split = record["split"] as? Double,
              let description = record["description"] as? String
        else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.description = description
        self.amount = amount
        self.split = split
        self.date = record.creationDate
    }
}

extension Transaction {
    static let sampleData: [Transaction] = [
        Transaction(id: "1", description: "Apple cider", amount: 4.50, split: 0.5, date: Date.now),
        Transaction(id: "2", description: "Apple pie", amount: 12.50, split: 0.8, date: Date.now)
    ]
}


