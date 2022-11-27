//
//  CoreDataStack.swift
//  Heath
//
//  Created by Dylan Hu on 11/20/22.
//

import CoreData
import CloudKit
import Combine

/**
 Class which provides an interface to the CloudKit-backed Core Data stack
 */
final class CoreDataStack: ObservableObject {
    static let shared: CoreDataStack = CoreDataStack()
    
    static var preview: CoreDataStack = {
        let result = CoreDataStack(inMemory: true)
        let viewContext = result.persistentContainer.viewContext
        for _ in 0..<10 {
            let newItem = Ledger(context: viewContext)
            newItem.createdAt = Date.now
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
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
    
    /**
     An operation queue for handling history processing tasks: watching changes, deduplicating tags, and triggering UI updates if needed.
     */
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    /**
     Track the last history token processed for a store, and write its value to file.
     
     The historyQueue reads the token when executing operations and updates it after processing is complete.
     */
    private var lastHistoryToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastHistoryToken,
                  let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) else { return }
            
            do {
                try data.write(to: tokenFile)
            } catch {
                print("###\(#function): Failed to write token data. Error = \(error)")
            }
        }
    }
    
    /**
     The file URL for persisting the persistent history token.
     */
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("CoreDataCloudKitDemo", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("###\(#function): Failed to create persistent container URL. Error = \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
    
    private var subscriptions: Set<AnyCancellable> = []
    private let inMemory: Bool
    
    init(inMemory: Bool = false) {
        self.inMemory = inMemory
        // Load the last token from the token file.
        if let tokenData = try? Data(contentsOf: tokenFile) {
            do {
                lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                print("###\(#function): Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
            }
        }
    }
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
        let container = NSPersistentCloudKitContainer(name: "Heath")
        guard let privateStoreDescription = container.persistentStoreDescriptions.first else {
            fatalError("#\(#function): Failed to retrieve a persistent store description.")
        }
        let storesURL = inMemory ? privateStoreDescription.url!.deletingLastPathComponent() : URL(fileURLWithPath: "/dev/null")
        privateStoreDescription.url = storesURL.appendingPathComponent("private.sqlite")
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        /// Add a second store and associate it with the CloudKit shared database
        guard let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription else {
            fatalError("#\(#function): Copying the private store description returned an unexpected value.")
        }
        sharedStoreDescription.url = storesURL.appendingPathComponent("shared.sqlite")
        let containerIdentifier = privateStoreDescription.cloudKitContainerOptions!.containerIdentifier
        let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
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
        container.viewContext.transactionAuthor = appTransactionAuthorName
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        /// Pin the viewContext to the current generation token and set it to keep itself up-to-date with local changes.
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation: \(error)")
        }
        
        // Observe Core Data remote change notifications.
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .sink {
                self.processRemoteStoreChange($0)
            }
            .store(in: &subscriptions)
        
        
        return container
    }
}

// MARK: - Notifications
extension CoreDataStack {
    /**
     Handle remote store change notifications (.NSPersistentStoreRemoteChange).
     */
    @objc
    func processRemoteStoreChange(_ notification: Notification) {
        // Process persistent history to merge changes from other coordinators.
        historyQueue.addOperation {
            self.processPersistentHistory()
        }
    }
}

// MARK: - Persistent history processing
extension CoreDataStack {
    /**
     Process persistent history, posting any relevant transactions to the current view.
     */
    func processPersistentHistory() {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.performAndWait {
            
            // Fetch history received from outside the app since the last token
            let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
            historyFetchRequest.predicate = NSPredicate(format: "author != %@", appTransactionAuthorName)
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
            request.fetchRequest = historyFetchRequest
            
            let result = (try? backgroundContext.execute(request)) as? NSPersistentHistoryResult
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction],
                  !transactions.isEmpty
            else { return }
            
            print("transactions = \(transactions)")
            self.mergeChanges(from: transactions)
            
            // Update the history token using the last transaction.
            lastHistoryToken = transactions.last!.token
        }
    }
    
    private func mergeChanges(from transactions: [NSPersistentHistoryTransaction]) {
        context.perform {
            transactions.forEach { [weak self] transaction in
                guard let self = self, let userInfo = transaction.objectIDNotification().userInfo else { return }
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [self.context])
            }
        }
    }
}
