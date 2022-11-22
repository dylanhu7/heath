//
//  ChannelRowView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI
import Contacts

struct ChannelRowView: View {
    let ledger: Ledger
    let shareable: Bool
    var body: some View {
//        let transaction = ledger.transactions[0]
        NavigationLink(destination: {
            ChannelView(ledger: ledger)
        }) {
            HStack {
                HStack {
//                    if let contact = ledger.contact {
//                        if contact.imageDataAvailable, let imageData = contact.thumbnailImageData {
//                            Image(data: imageData)?.resizable().aspectRatio(1, contentMode: .fit)
//                        }
//                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ledger.title ?? "").font(.headline)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
//                            Text("\(transaction.description) - ")
//                                .font(.subheadline).opacity(0.6)
//                            Text("$\(String(format: "%.2f", transaction.amount * transaction.split))")
//                                .font(.subheadline).opacity(0.6).fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 64)
    }
}

//struct ChannelRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            List {
//                ChannelRowView(channel: .constant(Channel.sampleData[0]), shareable: false)
//            }
//        }
//    }
//}
