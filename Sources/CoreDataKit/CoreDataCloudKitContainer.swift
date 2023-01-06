//  Copyright © 2022-2023 Keith Harrison. All rights reserved.
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

import CloudKit
import CoreData
import Foundation

/// `CoreDataCloudKitContainer` is a subclass of `NSPersistentCloudKitContainer`
/// for creating and using a Core Data stack that syncs with CloudKit.
///
/// CoreDataCloudKitContainer is a subclass of NSPersistentCloudKitContainer capable of
/// managing both CloudKit-backed and non-cloud stores.
///
/// If you have a CloudKit container identifier in the app's
/// entitlements the first identifier is used to sync with a
/// private CloudKit store. Otherwise, the store is local.
///
/// If you want to change these defaults modify the store
/// description before you load the store.

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public final class CoreDataCloudKitContainer: NSPersistentCloudKitContainer {
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
    
    /// Creates and returns a `CoreDataCloudKitController` object. It creates the
    /// managed object model, persistent store coordinator and main managed
    /// object context but does not load the persistent store.
    ///
    /// The default container has a persistent store description
    /// configured with the following defaults:
    ///
    /// - `url`: container name appended to `defaultDirectoryURL`
    /// - `isReadOnly`: false
    /// - `shouldAddStoreAsynchronously`: true
    /// - `shouldInferMappingModelAutomatically`: true
    /// - `shouldMigrateStoreAutomatically`: true
    /// The following persistent store options are set by
    /// default:
    ///
    /// - `NSPersistentHistoryTrackingKey`: true
    /// - `NSPersistentStoreRemoteChangeNotificationPostOptionKey`: true
    ///
    /// If you have a CloudKit container identifier(s) in the app's
    /// entitlements the first identifier is assigned to the default
    /// container store. Otherwise, the store is local.
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
    /// - Parameter inMemory: Create the SQLite store in memory.
    ///   Default is `false`. Using an in-memory store overrides
    ///   the store url and sets `shouldAddStoreAsynchronously` to
    ///   `false.`
    ///
    /// - Returns: A `CoreDataCloudKitController` object.
    
    public convenience init(name: String, bundle: Bundle = .main, inMemory: Bool = false) {
        guard let momURL = bundle.url(forResource: name, withExtension: "momd") else {
            fatalError("Unable to find \(name).momd in bundle \(bundle.bundleURL)")
        }
        
        guard let mom = NSManagedObjectModel(contentsOf: momURL) else {
            fatalError("Unable to create model from \(momURL)")
        }
        
        self.init(name: name, mom: mom, inMemory: inMemory)
    }
    
    /// Creates and returns a `CoreDataCloudKitController` object. It creates the
    /// persistent store coordinator and main managed object context but
    /// does not load the persistent store.
    ///
    /// The default container has a persistent store description
    /// configured with the following defaults:
    ///
    /// - `url`: container name appended to `defaultDirectoryURL`
    /// - `isReadOnly`: false
    /// - `shouldAddStoreAsynchronously`: true
    /// - `shouldInferMappingModelAutomatically`: true
    /// - `shouldMigrateStoreAutomatically`: true
    ///
    /// The following persistent store options are set by
    /// default:
    ///
    /// - `NSPersistentHistoryTrackingKey`: true
    /// - `NSPersistentStoreRemoteChangeNotificationPostOptionKey`: true
    ///
    /// If you have a CloudKit container identifier(s) in the app's
    /// entitlements the first identifier is assigned to the default
    /// container store. Otherwise, the store is local.
    ///
    /// If you want to change these defaults modify the store
    /// description before you load the store.
    ///
    /// - Parameter name: The name of the persistent container.
    ///   By default, this is used to name the persistent store
    ///   sql file.
    ///
    /// - Parameter mom: The managed object model.
    ///
    /// - Parameter inMemory: Create the SQLite store in memory.
    ///   Default is `false`. Using an in-memory store overrides
    ///   the store url and sets `shouldAddStoreAsynchronously` to
    ///   `false.`
    ///
    /// - Returns: A `CoreDataCloudKitController` object.
    
    public init(name: String, mom: NSManagedObjectModel, inMemory: Bool = false) {
        super.init(name: name, managedObjectModel: mom)
        configureDefaults(inMemory: inMemory)
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
    
    /// Load the persistent store.
    ///
    /// Call this method after creating the container to load the store.
    /// After the store has been loaded, the view context is configured
    /// as follows:
    ///
    /// - `automaticallyMergesChangesFromParent`: `true`
    /// - `name`: `viewContext`
    /// - `mergePolicy`: `NSMergeByPropertyObjectTrumpMergePolicy`
    ///
    /// The query generation is also pinned to the current generation
    /// (unless this is an in-memory store).
    ///
    /// - Parameter handler: This handler block is executed on the calling
    ///   thread when the loading of the persistent store has completed.
    
    override public func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
        super.loadPersistentStores { storeDescription, error in
            var completionError: Error? = error
            if error == nil {
                self.viewContext.automaticallyMergesChangesFromParent = true
                self.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                self.viewContext.name = "viewContext"
                self.viewContext.transactionAuthor = self.appTransactionAuthorName
                
                // Pin the view context to the current query generation.
                // This is not supported for an in-memory store
                if storeDescription.url != URL(fileURLWithPath: "/dev/null") {
                    completionError = self.pin(self.viewContext)
                }
            }
            block(storeDescription, completionError)
        }
    }
       
    private func configureDefaults(inMemory: Bool = false) {
        if let storeDescription = persistentStoreDescriptions.first {
            storeDescription.shouldAddStoreAsynchronously = true
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            if inMemory {
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
                storeDescription.shouldAddStoreAsynchronously = false
            }
        }
    }
    
    private func pin(_ context: NSManagedObjectContext) -> Error? {
        do {
            try context.setQueryGenerationFrom(.current)
        } catch {
            return error
        }
        return nil
    }
}
