//
//  NewTransactionView.swift
//  Heath
//
//  Created by Dylan Hu on 11/29/22.
//

import SwiftUI

struct NewTransactionView: View {
    var body: some View {
        Form {
            Section {
                TextField("test", text: .constant("Hello"))
            }
        }
    }
}

struct NewTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack {
                
            }
                .sheet(isPresented: .constant(true)) {
                    NewTransactionView()
                }
        }
        
    }
}
