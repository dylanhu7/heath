//
//  ChannelView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI

struct ChannelView: View {
    @Binding var channel: Channel
    var body: some View {
        Text(channel.name)
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView(channel: .constant(Channel.sampleData[0]))
    }
}
