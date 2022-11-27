//
//  LedgerView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI
import Contacts

struct LedgerView: View {
    let ledger: Ledger
    var body: some View {
        let contact = ledger.contact
        Text(contact?.givenName ?? "")
    }
}
