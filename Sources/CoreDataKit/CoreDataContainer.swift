//  Copyright © 2021 Keith Harrison. All rights reserved.
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
/// - `url`: store name appended to `defaultDirectoryURL`
/// - `isReadOnly`: false
/// - `shouldAddStoreAsynchronously`: true
/// - `shouldInferMappingModelAutomatically`: true
/// - `shouldMigrateStoreAutomatically`: true
///
/// If you want to change these defaults modify the store
/// description before you load the store.

@available(iOS 10.0, macOS 10.12, watchOS 3.0, tvOS 10.0, *)
public final class CoreDataContainer: NSPersistentContainer {
    /// Default directory for the persistent stores
    /// - Returns: A `URL` for the directory containing the
    ///   persistent store files.
    ///
    /// - Note: Adding the launch argument "-UNITTEST" to the
    ///   scheme appends the directory "UNITTEST" to the
    ///   default directory returned by `NSPersistentContainer`.
    
    public override class func defaultDirectoryURL() -> URL {
        if ProcessInfo.processInfo.arguments.contains("-UNITTEST") {
            return super.defaultDirectoryURL().appendingPathComponent("UNITTEST", isDirectory: true)
        }
        return super.defaultDirectoryURL()
    }
        
    /// Creates and returns a `CoreDataController` object. It creates the
    /// managed object model,persistent store coordinator and main managed
    /// object context but does not load the persistent store.
    ///
    /// - Parameter name: The name of the persistent container.
    ///   By default, this will also be used at the model name.
    /// - Parameter bundle: An optional bundle to load the model from.
    ///   The default is to look in the `.main` bundle.
    /// - Parameter inMemory: Create the SQLite store in memory.
    ///   Default is `false`.
    /// - Returns: A `CoreDataController` object.
    
    public init(name: String, bundle: Bundle = .main, inMemory: Bool = false) {
        guard let mom = NSManagedObjectModel.mergedModel(from: [bundle]) else {
            fatalError("Failed to load mom")
        }
        super.init(name: name, managedObjectModel: mom)
        configureDefaults(inMemory)
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
    ///
    /// - Parameter handler: This handler block is executed on the calling
    ///   thread when the loading of the persistent store has completed.
    
    public override func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
        super.loadPersistentStores { storeDescription, error in
            if error == nil {
                self.isStoreLoaded = true
                self.viewContext.automaticallyMergesChangesFromParent = true
                self.viewContext.name = "viewContext"
                self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
            block(storeDescription, error)
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
    
    private func configureDefaults(_ inMemory: Bool = false) {
        if let storeDescription = persistentStoreDescriptions.first {
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldAddStoreAsynchronously = true
            storeDescription.isReadOnly = false
            
            if inMemory {
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
                storeDescription.shouldAddStoreAsynchronously = false
            }
        }
    }
}
