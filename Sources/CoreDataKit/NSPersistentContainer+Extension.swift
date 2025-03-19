//  Copyright © 2025 Keith Harrison. All rights reserved.
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

extension NSPersistentContainer {
    /// Export the persistent store to a new location
    ///
    /// The first persistent store, if any, is migrated
    /// to the new location.
    ///
    /// The SQLite WAL mode is disabled on the exported
    /// store to force a checkpoint of all changes.
    ///
    /// - Parameter url: Destination URL
    @available(macOS 12.0, iOS 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, *)
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
    
    /// Remove all stores from the persistent store coordinator.
    public func removeStores() throws {
        for store in persistentStoreCoordinator.persistentStores {
            try persistentStoreCoordinator.remove(store)
        }
    }
    
    /// Delete the SQLite files for a store.
    ///
    /// Deletes the `.db`, `.db-shm` and `.db-wal` files
    /// for an SQLite persistent store.
    ///
    /// - Parameters:
    ///   - name: The name of the store (without extension).
    ///   - pathExtension: File extension. Default is "db".
    ///   - directoryURL: Optional URL for the containing directory.
    ///     Defaults to nil which uses the default container directory.
    public class func deleteStore(name: String, pathExtension: String = "db", directoryURL: URL? = nil) {
        let baseURL = directoryURL ?? CoreDataContainer.defaultDirectoryURL()
        
        let fileURL: URL
        if #available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, visionOS 1.0, watchOS 9.0, *) {
            fileURL = baseURL.appending(path: name, directoryHint: .notDirectory)
        } else {
            fileURL = baseURL.appendingPathComponent(name, isDirectory: false)
        }
        
        let dbURL = fileURL.appendingPathExtension(pathExtension)
        try? FileManager.default.removeItem(at: dbURL)

        let shmURL = fileURL.appendingPathExtension("\(pathExtension)-shm")
        try? FileManager.default.removeItem(at: shmURL)

        let walURL = fileURL.appendingPathExtension("\(pathExtension)-wal")
        try? FileManager.default.removeItem(at: walURL)
        
        let journalURL = fileURL.appendingPathExtension("\(pathExtension)-journal")
        try? FileManager.default.removeItem(at: journalURL)
    }
    
    /// Pin the context to the current store generation.
    ///
    /// The context is advanced when you call save, merge,
    /// or reset the context.
    ///
    /// - Parameter context: Managed object context to ping
    /// - Returns: Error or `nil` if successful.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func pin(_ context: NSManagedObjectContext) -> Error? {
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
