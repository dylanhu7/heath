//
//  CoreDataStack.swift
//  Heath
//
//  Created by Dylan Hu on 11/20/22.
//

import CoreData
import CloudKit

/**
 Class which provides an interface to the CloudKit-backed Core Data stack
 */
final class CoreDataStack: ObservableObject {
    static let shared: CoreDataStack = CoreDataStack()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    var privatePersistentStore: NSPersistentStore {
        guard let privateStore = _privatePersistentStore else {
            fatalError("Private store is not set")
        }
        return privateStore
    }
    
    var sharedPersistentStore: NSPersistentStore {
        guard let sharedStore = _sharedPersistentStore else {
            fatalError("Shared store is not set")
        }
        return sharedStore
    }
    
    private var _privatePersistentStore: NSPersistentStore?
    private var _sharedPersistentStore: NSPersistentStore?
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = initializePersistentCloudKitContainer()
    
    lazy var cloudKitContainer: CKContainer = CKContainer(identifier: Config.containerIdentifier)
}

// MARK: - Modify Core Data
extension CoreDataStack {
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("ViewContext save error: \(error)")
            }
        }
    }
    
    func delete(ledger: Ledger) {
        context.perform {
            self.context.delete(ledger)
            self.save()
        }
    }
}

// MARK: - Share a record from Core Data
extension CoreDataStack {
    func isShared(object: NSManagedObject) -> Bool {
        isShared(objectID: object.objectID)
    }
    
    func canEdit(object: NSManagedObject) -> Bool {
        return persistentContainer.canUpdateRecord(forManagedObjectWith: object.objectID)
    }
    
    func canDelete(object: NSManagedObject) -> Bool {
        return persistentContainer.canDeleteRecord(forManagedObjectWith: object.objectID)
    }
    
    func isOwner(object: NSManagedObject) -> Bool {
        guard isShared(object: object) else { return false }
        guard let share = try? persistentContainer.fetchShares(matching: [object.objectID])[object.objectID] else {
            print("Get ckshare error")
            return false
        }
        if let currentUser = share.currentUserParticipant, currentUser == share.owner {
            return true
        }
        return false
    }
    
    func getShare(_ ledger: Ledger) -> CKShare? {
        guard isShared(object: ledger) else { return nil }
        guard let shareDictionary = try? persistentContainer.fetchShares(matching: [ledger.objectID]),
              let share = shareDictionary[ledger.objectID] else {
            print("Unable to get CKShare")
            return nil
        }
        share[CKShare.SystemFieldKey.title] = ledger.title
        return share
    }
    
    private func isShared(objectID: NSManagedObjectID) -> Bool {
        var isShared = false
        if let persistentStore = objectID.persistentStore {
            if persistentStore == sharedPersistentStore {
                isShared = true
            } else {
                let container = persistentContainer
                do {
                    let shares = try container.fetchShares(matching: [objectID])
                    if shares.first != nil {
                        isShared = true
                    }
                } catch {
                    print("Failed to fetch share for \(objectID): \(error)")
                }
            }
        }
        return isShared
    }
}


// MARK: - Initialize Container
extension CoreDataStack {
    private func initializePersistentCloudKitContainer() -> NSPersistentCloudKitContainer {
        let (privateStoreFolderURL, sharedStoreFolderURL) = createPersistentStoresDirectory()
        let container = NSPersistentCloudKitContainer(name: "Heath")
        
        /// Associate default store with the CloudKit private database
        guard let privateStoreDescription = container.persistentStoreDescriptions.first else {
            fatalError("#\(#function): Failed to retrieve a persistent store description.")
        }
        privateStoreDescription.url = privateStoreFolderURL.appendingPathComponent("private.sqlite")
        /// Enable history tracking
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        /// Enable remote notifications
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        /// Specify database scope
        let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Config.containerIdentifier)
        cloudKitContainerOptions.databaseScope = .private
        privateStoreDescription.cloudKitContainerOptions = cloudKitContainerOptions
        
        /// Add a second store and associate it with the CloudKit shared database
        guard let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription else {
            fatalError("#\(#function): Copying the private store description returned an unexpected value.")
        }
        sharedStoreDescription.url = sharedStoreFolderURL.appendingPathComponent("shared.sqlite")
        let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Config.containerIdentifier)
        sharedStoreOptions.databaseScope = .shared
        sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
        
        /// Load stores
        container.persistentStoreDescriptions.append(sharedStoreDescription)
        container.loadPersistentStores(completionHandler: { (loadedStoreDescription, error) in
            guard error == nil else { fatalError("#\(#function): Failed to load persistent stores: \(error!)") }
            guard let cloudKitContainerOptions = loadedStoreDescription.cloudKitContainerOptions else { return }
            if cloudKitContainerOptions.databaseScope == .private {
                self._privatePersistentStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
            } else if cloudKitContainerOptions.databaseScope == .shared {
                self._sharedPersistentStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
            }
        })
        
        /// Automatically merge the changes from other contexts.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        /// Pin the viewContext to the current generation token and set it to keep itself up-to-date with local changes.
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation: \(error)")
        }
        
        /**
         Run initializeCloudKitSchema() once to update the CloudKit schema every time you change the Core Data model.
         Don't call this code in the production environment.
         */
#if InitializeCloudKitSchema
        do {
            try container.initializeCloudKitSchema()
        } catch {
            print("\(#function): initializeCloudKitSchema: \(error)")
        }
#endif
        
        return container
    }
    
    /**
     Create `CoreDataStores` directory to hold private and shared stores
     
     Private store at `CoreDataStores/Private`
     Shared store at `CoreDataStores/Shared`
     */
    private func createPersistentStoresDirectory() -> (privateStoreFolderURL: URL, sharedStoreFolderURL: URL) {
        let baseURL = NSPersistentContainer.defaultDirectoryURL()
        let storeFolderURL = baseURL.appendingPathComponent("CoreDataStores")
        let privateStoreFolderURL = storeFolderURL.appendingPathComponent("Private")
        let sharedStoreFolderURL = storeFolderURL.appendingPathComponent("Shared")
        
        let fileManager = FileManager.default
        for folderURL in [privateStoreFolderURL, sharedStoreFolderURL] where !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("#\(#function): Failed to create the store folder: \(error)")
            }
        }
        return (privateStoreFolderURL, sharedStoreFolderURL)
    }
}
