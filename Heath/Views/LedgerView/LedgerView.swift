//
//  LedgerView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI
import Contacts

struct LedgerView: View {
    @ObservedObject var ledger: Ledger
    @State private var newTransaction: Transaction?
    @State private var creatingNewTransaction: Bool = false
    var body: some View {
        let name = formattedName()
        let balance = formattedBalance()
        VStack {
            LedgerHeaderView(ledger: ledger, name: name, balance: balance)
            Section(
                header: HStack {
                    Text("History").font(.title).fontWeight(.semibold).foregroundColor(.accentColor)
                    Spacer()
                }) {
                    ForEach(ledger.sortedTransactions) { transaction in
                        Text(transaction.detail ?? "No detail")
                    }
            }
            .headerProminence(.increased)
            Spacer()
            TrackSpendingButtonView(creatingNewTransaction: $creatingNewTransaction)
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {  }) { Image(systemName: "ellipsis") }
            }
        }
        .sheet(isPresented: $creatingNewTransaction) {
            NewTransactionView(ledger: ledger)
        }
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
