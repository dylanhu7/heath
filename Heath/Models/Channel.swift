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
    
    init(zone: CKRecordZone, transactions: [Transaction]) {
        let contactStore = CNContactStore()
        self.transactions = transactions
        self.id = zone.zoneID.zoneName
        self.ownerName = zone.zoneID.ownerName
        do {
            let contact = try contactStore.unifiedContact(withIdentifier: zone.zoneID.zoneName, keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName)])
            self.name = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName) ?? ""
        } catch {
            self.name = ""
        }
    }
}
