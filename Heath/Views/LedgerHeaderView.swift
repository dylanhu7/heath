//
//  LedgerHeaderView.swift
//  Heath
//
//  Created by Dylan Hu on 11/27/22.
//

import SwiftUI
import Contacts

struct LedgerHeaderView: View {
    let ledger: Ledger
    let name: String
    let balance: String
    var body: some View {
        let contact = ledger.contact
        VStack {
            HStack(spacing: 16) {
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
                    Text(name).font(.title2).fontWeight(.semibold)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        if ledger.balance <= 0 {
                            Text("You owe: ")
                                .font(.headline).opacity(0.6)
                            Text("\(balance)")
                                .font(.headline).fontWeight(.semibold)
                                .foregroundColor(ledger.balance != 0 ? Color.red : Color.primary)
                        } else {
                            Text("Owes you: ")
                                .font(.headline).opacity(0.6)
                            Text("\(balance)")
                                .font(.headline).fontWeight(.semibold)
                                .foregroundColor(Color.green)
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: 84)
            HStack {
                
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 112)
        .background(Color.white)
        .cornerRadius(10)
    }
}
