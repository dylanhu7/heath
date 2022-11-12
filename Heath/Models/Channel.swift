//
//  Channel.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import Foundation
import CloudKit
import Contacts

struct Channel: Identifiable {
    var name: String
    let zone: CKRecordZone
    let transactions: [Transaction]
    var id: String {
        zone.zoneID.zoneName
    }
    
    init(zone: CKRecordZone, transactions: [Transaction]) {
        let contactStore = CNContactStore()
        self.zone = zone
        self.transactions = transactions
        let keysToFetch = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor
        ]
        do {
            let contact = try contactStore.unifiedContact(withIdentifier: zone.zoneID.zoneName, keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName)])
            self.name = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName) ?? ""
        } catch {
            self.name = ""
        }
    }
}
