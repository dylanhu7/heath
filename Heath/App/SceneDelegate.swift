//
//  SceneDelegate.swift
//  Heath
//
//  Created by Dylan Hu on 11/13/22.
//

import UIKit
import SwiftUI
import CloudKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        guard cloudKitShareMetadata.containerIdentifier == Config.containerIdentifier else {
            debugPrint("Shared container identifier \(cloudKitShareMetadata.containerIdentifier) did not match known identifier.")
            return
        }

        let stack = CoreDataStack.shared

        // Get references to the app's persistent container
        // and shared persistent store.
        let container = stack.persistentContainer
        let store = stack.sharedPersistentStore

        // Tell the container to accept the specified share, adding
        // the shared objects to the shared persistent store.
        container.acceptShareInvitations(from: [cloudKitShareMetadata],
                                         into: store,
                                         completion: nil)
    }
}
