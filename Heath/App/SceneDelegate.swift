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
        
        // Create an operation to accept the share, running in the app's CKContainer.
        let container = CKContainer(identifier: Config.containerIdentifier)
        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        
        debugPrint("Accepting CloudKit Share with metadata: \(cloudKitShareMetadata)")

        operation.perShareResultBlock = { metadata, result in
            let shareRecordType = metadata.share.recordType

            switch result {
            case .failure(let error):
                debugPrint("Error accepting share: \(error)")

            case .success:
                debugPrint("Accepted CloudKit share with type: \(shareRecordType)")
            }
        }

        operation.acceptSharesResultBlock = { result in
            if case .failure(let error) = result {
                debugPrint("Error accepting CloudKit Share: \(error)")
            }
        }

        operation.qualityOfService = .utility
        container.add(operation)
    }
}
