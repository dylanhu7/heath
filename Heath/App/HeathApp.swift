//
//  HeathApp.swift
//  Heath
//
//  Created by Dylan Hu on 11/1/22.
//

import SwiftUI

@main
struct HeathApp: App {
    @StateObject private var store = ChannelStore()
    @State private var errorWrapper: ErrorWrapper?
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.purple]
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(channels: $store.channels)
            }
            .task {
                do {
                    store.channels = try await ChannelStore.load()
                } catch {
                    errorWrapper = ErrorWrapper(error: error, guidance: "Loading channels failed, try again later")
                }
            }
            .sheet(item: $errorWrapper) { wrapper in
                ErrorView(errorWrapper: wrapper)
            }
        }
    }
}
