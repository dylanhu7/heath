//
//  ChannelsListView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI

struct ChannelsListView: View {
    @Binding var channels: [Channel]
    var body: some View {
        List {
            ForEach($channels) {
                ChannelRowView(channel: $0, shareable: true)
            }
        }
    }
}

struct ChannelsListView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelsListView(channels: .constant(Channel.sampleData))
    }
}
