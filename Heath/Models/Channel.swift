//
//  Channel.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import Foundation
import CloudKit
import Contacts

struct Channel: Identifiable, Codable {
    let name: String
    let id: String
    let ownerName: String
    let transactions: [Transaction]
    
    init(name: String, id: String, ownerName: String, transactions: [Transaction]) {
        self.name = name
        self.id = id
        self.ownerName = ownerName
        self.transactions = transactions
    }
    
    init(zone: CKRecordZone, transactions: [Transaction]) {
        self.transactions = transactions
        self.id = zone.zoneID.zoneName
        self.ownerName = zone.zoneID.ownerName
        do {
            let contact = try ChannelStore.contactStore.unifiedContact(withIdentifier: zone.zoneID.zoneName, keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName)])
            self.name = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName) ?? ""
        } catch {
            self.name = ""
        }
    }
}

extension Channel {
    static let sampleData: [Channel] = [
        Channel(name: "Johnny Appleseed", id: "1", ownerName: "WQIOGIOR", transactions: []),
        Channel(name: "Heath Ledger", id: "2", ownerName: "WQIOGIOR", transactions: [])
    ]
}
