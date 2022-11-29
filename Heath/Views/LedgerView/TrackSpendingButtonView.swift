//
//  TrackSpendingButtonView.swift
//  Heath
//
//  Created by Dylan Hu on 11/29/22.
//

import SwiftUI

struct TrackSpendingButtonView: View {
    @Binding var creatingNewTransaction: Bool
    var body: some View {
        Button {
            creatingNewTransaction = true
        } label: {
            Label("Track Spending", systemImage: "square.and.pencil")
        }
    }
}

struct TrackSpendingButtonView_Previews: PreviewProvider {
    static var previews: some View {
        TrackSpendingButtonView(creatingNewTransaction: .constant(false))
    }
}
