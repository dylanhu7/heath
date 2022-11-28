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
        let name = formattedName()
        let balance = formattedBalance()
        VStack {
            LedgerHeaderView(ledger: ledger, name: name, balance: balance)
            Spacer()
            Section("History") {
                EmptyView()
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func formattedName() -> String {
        guard let contact = ledger.contact else { return "Unknown Contact" }
        return CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName) ?? "Unknown Contact"
    }
    
    private func formattedBalance() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: ledger.balance)) ?? "$0.00"
    }
}
