//
//  LedgerRowView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI
import Contacts
import CloudKit

struct LedgerRowView: View {
    @ObservedObject var ledger: Ledger
    var body: some View {
        let contact = ledger.contact
        let transaction = ledger.sortedTransactions.first
        NavigationLink(destination: {
            LedgerView(ledger: ledger)
        }) {
            HStack {
                HStack(spacing: 12) {
                    if let imageData = contact?.thumbnailImageData {
                        Image(data: imageData)?
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(.infinity)
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(.infinity)
                            .foregroundColor(.gray)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(contact?.givenName ?? "Unknown Contact").font(.headline)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            if let transaction {
                                if let detail = transaction.detail {
                                    Text("\(detail) - ")
                                        .font(.subheadline).opacity(0.6)
                                }
                                Text("$\(String(format: "%.2f", transaction.amount * transaction.split))")
                                    .font(.subheadline).opacity(0.6).fontWeight(.semibold)
                            } else {
                                Text("No transactions yet!")
                                    .font(.subheadline).opacity(0.6)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 56)
    }
}

