//
//  Ledger+CoreDataClass.swift
//  Heath
//
//  Created by Dylan Hu on 11/21/22.
//
//

import Foundation
import CoreData

@objc(Ledger)
public class Ledger: NSManagedObject {
    static var all: NSFetchRequest<Ledger> {
        let request = Ledger.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
}
