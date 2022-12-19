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
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }.environment(\.managedObjectContext, CoreDataStack.shared.context)
        }
    }
}
