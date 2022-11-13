//
//  ChannelRowView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI

struct ChannelRowView: View {
    let channel: Channel
    let shareable: Bool
    var body: some View {
        HStack {
            Text(channel.name)
        }
    }
}

struct ChannelRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            
        }
    }
}
