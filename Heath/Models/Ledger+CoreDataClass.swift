//
//  Ledger+CoreDataClass.swift
//  Heath
//
//  Created by Dylan Hu on 11/21/22.
//
//

import Foundation
import CoreData
import Contacts
import CloudKit

@objc(Ledger)
public class Ledger: NSManagedObject {
    static let contactStore = CNContactStore()
    static let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName),
                              CNContactThumbnailImageDataKey as CNKeyDescriptor,
                              CNContactImageDataAvailableKey as CNKeyDescriptor]
    
    public override func willSave() {
        super.willSave()
        setPrimitiveValue(
            Date.now,
            forKey: "lastModified"
        )
    }
    
    static var all: NSFetchRequest<Ledger> {
        let request = Ledger.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
    
    lazy var contact: CNContact? = {
        guard let share = CoreDataStack.shared.getShare(self) else { return nil }
        let isOwner = CoreDataStack.shared.isOwner(object: self)
        let otherRole = isOwner ? CKShare.ParticipantRole.privateUser : CKShare.ParticipantRole.owner
        var participants = share.participants
        let index = participants.partition(by: { $0.role == otherRole })
        guard index < participants.count else { return nil }
        let otherParticipant = participants[index]
        let identifiers = otherParticipant.userIdentity.contactIdentifiers
        var predicate: NSPredicate
        if let phoneNumber = otherParticipant.userIdentity.lookupInfo?.phoneNumber {
            predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: phoneNumber))
        } else if let emailAddress = otherParticipant.userIdentity.lookupInfo?.emailAddress {
            predicate = CNContact.predicateForContacts(matchingEmailAddress: emailAddress)
        } else {
            return nil
        }
        do {
            let contacts = try Ledger.contactStore.unifiedContacts(matching: predicate, keysToFetch: Ledger.keysToFetch)
            return contacts.first
        } catch {
            debugPrint("ERROR: failed to get contacts: \(error)")
            return nil
        }
    }()
    
    lazy var balance: Double = {
        var balance: Double = 0
        let isOwner = CoreDataStack.shared.isOwner(object: self)
        guard let transactions else { return 0 }
        transactions.forEach({ transaction in
            let transaction = transaction as! Transaction
            let difference = transaction.amount * (transaction.split)
            balance = isOwner ? balance + difference : balance - difference
        })
        return balance
    }()
}
