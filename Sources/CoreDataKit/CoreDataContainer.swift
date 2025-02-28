//  Copyright © 2021-2023 Keith Harrison. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.

import CoreData
import Foundation

/// `CoreDataContainer` is a subclass of `NSPersistentContainer`
/// for creating and using a Core Data stack.
///
/// The persistent store description that will be used to
/// create/load the store is configured with the following
/// defaults:
///
/// - `shouldAddStoreAsynchronously`: true
///
/// The following persistent store options are set by
/// default:
///
/// - `NSPersistentHistoryTrackingKey`: true
///
/// If you want to change these defaults modify the store
/// description before you load the store.

@available(iOS 10.0, macOS 10.12, watchOS 3.0, tvOS 10.0, *)
public class CoreDataContainer: NSPersistentContainer, @unchecked Sendable {
    /// Author used for the viewContext as an identifier
    /// in persistent history transactions.
    
    public var appTransactionAuthorName = "app"

    /// Default directory for the persistent stores
    /// - Returns: A `URL` for the directory containing the
    ///   persistent store files.
    ///
    /// - Note: Adding the launch argument "-UNITTEST" to the
    ///   scheme appends the directory "UNITTEST" to the
    ///   default directory returned by `NSPersistentContainer`.
    
    override public class func defaultDirectoryURL() -> URL {
        if ProcessInfo.processInfo.arguments.contains("-UNITTEST") {
            return super.defaultDirectoryURL().appendingPathComponent("UNITTEST", isDirectory: true)
        }
        return super.defaultDirectoryURL()
    }
            
    /// Creates and returns a `CoreDataController` object. It creates the
    /// managed object model, persistent store coordinator and main managed
    /// object context but does not load the persistent store.
    ///
    /// The default container has a persistent store description
    /// configured with the following defaults:
    ///
    /// - `shouldAddStoreAsynchronously`: true
    ///
    /// The following persistent store options are set by
    /// default:
    ///
    /// - `NSPersistentHistoryTrackingKey`: true
    ///
    /// If you want to change these defaults modify the store
    /// description before you load the store.
    ///
    /// - Parameter name: The name of the persistent container.
    ///   By default, this will also be used as the name of the
    ///   managed object model and persistent store sql file.
    ///
    /// - Parameter bundle: An optional bundle to load the model(s) from.
    ///   Default is `.main`.
    ///
    /// - Parameter url: A URL for the location of the persistent store.
    ///   If not specified the store is created using the container name
    ///   in the default container directory. Default is `nil`.
    ///
    /// - Parameter inMemory: Create the SQLite store in memory.
    ///   Default is `false`. Using an in-memory store overrides
    ///   the store url and sets `shouldAddStoreAsynchronously` to
    ///   `false.`
    
    public convenience init(name: String, bundle: Bundle = .main, url: URL? = nil, inMemory: Bool = false) {
        guard let momURL = bundle.url(forResource: name, withExtension: "momd") else {
            fatalError("Unable to find \(name).momd in bundle \(bundle.bundleURL)")
        }
        
        guard let mom = NSManagedObjectModel(contentsOf: momURL) else {
            fatalError("Unable to create model from \(momURL)")
        }

        self.init(name: name, mom: mom, url: url, inMemory: inMemory)
    }

    /// Creates and returns a `CoreDataController` object. It creates the
    /// persistent store coordinator and main managed object context but
    /// does not load the persistent store.
    ///
    /// - Parameter name: The name of the persistent container.
    ///   By default, this is used to name the persistent store
    ///   sql file.
    ///
    /// - Parameter mom: The managed object model.
    ///
    /// - Parameter url: A URL for the location of the persistent store.
    ///   If not specified the store is created using the container name
    ///   in the default container directory. Default is `nil`.
    ///
    /// - Parameter inMemory: Create the SQLite store in memory.
    ///   Default is `false`. Using an in-memory store overrides
    ///   the store url and sets `shouldAddStoreAsynchronously` to
    ///   `false.`
    
    public init(name: String, mom: NSManagedObjectModel, url: URL? = nil, inMemory: Bool = false) {
        super.init(name: name, managedObjectModel: mom)
        configureDefaults(url: url, inMemory: inMemory)
    }
    
    /// The `URL` of the persistent store for this Core Data Stack. If there
    /// is more than one store this property returns the first store it finds.
    /// The store may not yet exist. It will be created at this URL by default
    /// when first loaded.

    public var storeURL: URL? {
        guard let firstDescription = persistentStoreDescriptions.first else {
            return nil
        }
        return firstDescription.url
    }

    /// A read-only flag indicating if the persistent store is loaded.
    public private(set) var isStoreLoaded = false

    /// Load the persistent store.
    ///
    /// Call this method after creating the container to load the store.
    /// After the store has been loaded, the view context is configured
    /// as follows:
    ///
    /// - `automaticallyMergesChangesFromParent`: `true`
    /// - `name`: `viewContext`
    /// - `mergePolicy`: `NSMergeByPropertyObjectTrumpMergePolicy`
    /// - `transactionAuthor`: see `appTransactionAuthorName`.
    ///
    /// The query generation is also pinned to the current generation
    /// (unless this is an in-memory store).
    ///
    /// - Parameter block: This handler block is executed on the calling
    ///   thread when the loading of the persistent store has completed.
    
    override public func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
        super.loadPersistentStores { storeDescription, error in
            var completionError: Error? = error
            if error == nil {
                self.isStoreLoaded = true
                self.viewContext.automaticallyMergesChangesFromParent = true
                self.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                self.viewContext.name = "viewContext"
                self.viewContext.transactionAuthor = self.appTransactionAuthorName
                
                // Pin the view context to the current query generation.
                // This is not supported for an in-memory store
                if storeDescription.url != URL(fileURLWithPath: "/dev/null") {
                    if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
                        completionError = self.pin(self.viewContext)
                    }
                }
            }
            block(storeDescription, completionError)
        }
    }
    
    /// Returns a new managed object context that executes
    /// on a private queue.
    ///
    /// The merge policy is property object trump
    /// and the undo manager is disabled.
    public override func newBackgroundContext() -> NSManagedObjectContext {
        let context = super.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        return context
    }
    
    /// Export the persistent store to a new location
    ///
    /// The first persistent store, if any, is migrated
    /// to the new location.
    ///
    /// The SQLite WAL mode is disabled on the exported
    /// store to force a checkpoint of all changes.
    ///
    /// - Parameter url: Destination URL
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func exportStore(to url: URL) throws {
        guard let store = persistentStoreCoordinator.persistentStores.first else {
            return
        }
        
        // Options to disable WAL mode
        let options = [
            NSSQLitePragmasOption: ["journal_mode": "DELETE"]
        ]
        
        // If the destination store exists, empty the database.
        // This doesn't delete the database file.
        _ = try persistentStoreCoordinator.destroyPersistentStore(
            at: url,
            type: .sqlite,
            options: options
        )
        
        // Move the existing store to the new location
        _ = try persistentStoreCoordinator.migratePersistentStore(
            store,
            to: url,
            options: options,
            type: .sqlite
        )
    }
    
    /// Remove the first store from the persistent
    /// store coordinator.
    public func removeStore() throws {
        if let store = persistentStoreCoordinator.persistentStores.first {
            try persistentStoreCoordinator.remove(store)
        }
    }
    
    /// Delete the SQLite files for a store.
    ///
    /// Deletes the `.sqlite`, `.sqlite=shm` and `.sqlite-wal` files
    /// for an SQLite persistent store.
    ///
    /// - Parameters:
    ///   - name: The name of the store (without extension).
    ///   - directoryURL: Optional URL for the containing directory.
    ///     Defaults to nil which uses the default container directory.
    
    public class func deleteStore(name: String, directoryURL: URL? = nil) {
        let baseURL = directoryURL ?? CoreDataContainer.defaultDirectoryURL()
        let sqliteURL = baseURL.appendingPathComponent("\(name).sqlite", isDirectory: false)
        try? FileManager.default.removeItem(at: sqliteURL)

        let shmURL = baseURL.appendingPathComponent("\(name).sqlite-shm", isDirectory: false)
        try? FileManager.default.removeItem(at: shmURL)

        let walURL = baseURL.appendingPathComponent("\(name).sqlite-wal", isDirectory: false)
        try? FileManager.default.removeItem(at: walURL)
        
        let journalURL = baseURL.appendingPathComponent("\(name).sqlite-journal", isDirectory: false)
        try? FileManager.default.removeItem(at: journalURL)
    }
    
    private func configureDefaults(url: URL?, inMemory: Bool) {
        if let storeDescription = persistentStoreDescriptions.first {
            storeDescription.shouldAddStoreAsynchronously = true
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            if let url {
                storeDescription.url = url
            }
            if inMemory {
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
                storeDescription.shouldAddStoreAsynchronously = false
            }
        }
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    private func pin(_ context: NSManagedObjectContext) -> Error? {
        let error: Error? = context.performAndWait {
            do {
                try context.setQueryGenerationFrom(.current)
                return nil
            } catch {
                return error
            }
        }
        return error
    }
}
