//
//  ChannelsListView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI

struct ChannelsListView: View {
    let ledgers: FetchedResults<Ledger>
    var body: some View {
        List {
            ForEach(ledgers) {
                ChannelRowView(ledger: $0, shareable: true)
            }
        }
    }
}

//struct ChannelsListView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            ChannelsListView()
//        }
//    }
//}
