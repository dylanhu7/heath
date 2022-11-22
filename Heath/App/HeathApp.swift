//
//  HeathApp.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import SwiftUI

@main
struct HeathApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    @State private var errorWrapper: ErrorWrapper?
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.purple]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.purple]
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView().environment(\.managedObjectContext, CoreDataStack.shared.context)
            }
            .sheet(item: $errorWrapper) { wrapper in
                ErrorView(errorWrapper: wrapper)
            }
        }
    }
}
