//
//  ContentView.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import SwiftUI
import Contacts

struct ContentView: View {
    @State private var isAddingContact = false
    @State var contact: CNContact?
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.purple]
    }
    
    var body: some View {
        List {
            Text(contact?.givenName ?? "")
        }
        .navigationTitle("Heath")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { Task {
                    
                } } label: { Image(systemName: "arrow.clockwise") }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isAddingContact = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isAddingContact, content: {
            ContactPicker(contact: $contact)})
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
        }
    }
}
