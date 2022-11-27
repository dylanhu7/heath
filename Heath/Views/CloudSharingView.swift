//
//  CloudSharingView.swift
//  Heath
//
//  Created by Dylan Hu on 11/22/22.
//

import SwiftUI
import Contacts
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            csc.dismiss(animated: true)
            debugPrint("ERROR: Failed to save share: \(error)")
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Item Title"
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Successfully saved share")
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            if !CoreDataStack.shared.isOwner(object: parent.ledger) {
                CoreDataStack.shared.delete(ledger: parent.ledger)
            }
        }
        
        var parent: CloudSharingView
        
        init(_ parent: CloudSharingView) {
            self.parent = parent
        }
        
    }
    
    let share: CKShare
    let container: CKContainer
    let ledger: Ledger
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
