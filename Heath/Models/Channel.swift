//
//  Channel.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import Foundation
import CloudKit

struct Channel {
    let zone: CKRecordZone
    let transactions: [Transaction]
    var name: String {
        zone.zoneID.zoneName
    }
}

extension Channel: Identifiable {
    var id: String {
        name
    }
}
