//
//  Channel.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import CloudKit
import Contacts

struct Channel: Identifiable, Codable {
    let name: String
    let id: String
    let ownerName: String
    var transactions: [Transaction]
    var contact: CNContact?
}

extension Channel {
    static let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName),
                              CNContactThumbnailImageDataKey as CNKeyDescriptor,
                              CNContactImageDataAvailableKey as CNKeyDescriptor]
    
    init(from zone: CKRecordZone, with transactions: [Transaction]? = nil) {
        self.transactions = transactions ?? []
        self.id = zone.zoneID.zoneName
        self.ownerName = zone.zoneID.ownerName
        do {
            contact = try ChannelStore.contactStore.unifiedContact(withIdentifier: zone.zoneID.zoneName, keysToFetch: Channel.keysToFetch)
            if let contact = contact {
                self.name = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName) ?? "Unknown"
            } else {
                self.name = "Unknown"
            }
        } catch {
            self.name = "Unknown"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, id, ownerName, transactions
    }
}

extension Channel {
    var sortedTransactions: [Transaction] {
        return transactions.sorted(by: {
            $0.date! < $1.date!
        })
    }
    
}

extension Channel {
    static var sampleData: [Channel] = [
        Channel(name: "Johnny Appleseed", id: "1", ownerName: "WQIOGIOR", transactions: Transaction.sampleData),
        Channel(name: "Heath Ledger", id: "2", ownerName: "WQIOGIOR", transactions: Transaction.sampleData)
    ]
}
