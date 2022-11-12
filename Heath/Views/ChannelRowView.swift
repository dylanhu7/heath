//
//  ChannelRowView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI

struct ChannelRowView: View {
    @Binding var channel: Channel
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
