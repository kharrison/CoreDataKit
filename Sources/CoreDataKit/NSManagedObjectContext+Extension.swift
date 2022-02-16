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

extension NSManagedObjectContext {
    /// Save the context
    ///
    /// If the current context has unsaved changes attempts
    /// to commit to parent store. If the save operation fails,
    /// rollback to the last committed state.
    ///
    /// - Returns: nil if successful or an NSError.
    ///
    /// - Note: You must perform this operation on the queue
    /// specified for the context.
    public func saveOrRollback() -> NSError? {
        guard hasChanges else { return nil }
        do {
            try save()
            return nil
        } catch {
            rollback()
            return error as NSError
        }
    }
    
    /// Asynchronously commit any unsaved changes on
    /// the context's queue. If the save fails the
    /// context is rolled back to the last
    /// committed state.
    public func performSaveOrRollback() {
        perform {
            _ = self.saveOrRollback()
        }
    }
    
    /// Asynchronously perform a block then commit any
    /// unsaved changes on the context's queue. If the
    /// save fails the context is rolled back to the
    /// last committed state.
    public func performThenSave(block: @escaping() -> ()) {
        perform {
            block()
            _ = self.saveOrRollback()
        }
    }
    
    /// Batch delete objects and optionally merge changes into multiple
    /// contexts.
    ///
    /// A batch delete is faster to delete multiple objects but it bypasses
    /// any validation rules and does not automatically update any of the
    /// objects which may be in memory unless you merge the change into the
    /// context.
    ///
    /// The batch delete is performed on a background managed object context.
    ///
    /// - Parameters:
    ///   - objectIDs: NSManagedObjectIDs of objects to delete.
    ///   - contexts: Optional array of managed object contexts which will
    ///     have the changes merged.
    public func batchDelete(objectIDs: [NSManagedObjectID], mergeInto contexts: [NSManagedObjectContext]? = nil) throws {
        guard !objectIDs.isEmpty else { return }
        
        let request = NSBatchDeleteRequest(objectIDs: objectIDs)
        request.resultType = .resultTypeObjectIDs
        let deleteResult = try execute(request) as? NSBatchDeleteResult
        
        if let contexts = contexts,
           let deletedIDs = deleteResult?.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: deletedIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: contexts)
        }
    }
}
