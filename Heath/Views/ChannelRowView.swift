//
//  ChannelRowView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI

struct ChannelRowView: View {
    @Binding var channel: Channel
    let shareable: Bool
    var body: some View {
        NavigationLink(destination: {
            ChannelView(channel: $channel)
        }) {
            HStack {
                Text(channel.name)
            }
        }
    }
}

struct ChannelRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ChannelRowView(channel: .constant(Channel.sampleData[0]), shareable: false)
        }
    }
}
