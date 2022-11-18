//
//  ChannelView.swift
//  Heath
//
//  Created by Dylan Hu on 11/12/22.
//

import SwiftUI
import Contacts

struct ChannelView: View {
    @Binding var channel: Channel
//    let contact = ChannelStore.contactStore.unifiedContact(withIdentifier: channel.id, keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName)])
    var body: some View {
        Text(channel.name)
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChannelView(channel: .constant(Channel.sampleData[0]))
        }
    }
}
