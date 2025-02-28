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
import CoreDataKit
import Testing

@MainActor struct CoreDataContainerTests {
    private let modelName = "CoreDataKit"
    private let container: CoreDataContainer

    init() {
        container = CoreDataContainer(
            name: modelName, bundle: .module, inMemory: true)
    }

    @Test func containerName() throws {
        #expect(modelName == container.name)
    }

    @Test func loadMOM() throws {
        let entities = container.managedObjectModel.entities
        #expect(entities.count == 1)
    }

    @Test func defaultStoreURL() throws {
        #expect(container.storeURL != nil)
    }

    @Test func storeNotLoaded() throws {
        #expect(!container.isStoreLoaded)
    }

    @Test func shouldMigrateStoreAutomatically() throws {
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        #expect(storeDescription.shouldMigrateStoreAutomatically)
    }

    @Test func shouldInferMappingModelAutomatically() throws {
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        #expect(
            storeDescription.shouldInferMappingModelAutomatically)
    }

    @Test func isNotReadOnly() throws {
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        #expect(!storeDescription.isReadOnly)
    }

    @Test func shouldAddStoreAsynchronouslyTrueByDefault() throws {
        let container = CoreDataContainer(name: modelName, bundle: .module)
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        #expect(storeDescription.shouldAddStoreAsynchronously)
    }

    @Test func shouldAddStoreAsynchronouslyFalseInMemory() throws {
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        #expect(!storeDescription.shouldAddStoreAsynchronously)
    }

    @Test func historyTrackingKeyTrueByDefault() throws {
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        let historyTrackingOption = try #require(
            storeDescription.options[NSPersistentHistoryTrackingKey]
                as? NSNumber)
        #expect(historyTrackingOption.boolValue)
    }

    @Test func createStoreInMemory() throws {
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        #expect(storeDescription.url == URL(fileURLWithPath: "/dev/null"))
    }

    @Test func createStoreWithCustomURL() throws {
        let url = FileManager.default.temporaryDirectory
        let container = CoreDataContainer(
            name: modelName, bundle: .module, url: url)
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        #expect(storeDescription.url == url)
    }

    @Test func inMemoryStoreOverridesCustomURL() throws {
        let url = FileManager.default.temporaryDirectory
        let container = CoreDataContainer(
            name: modelName, bundle: .module, url: url, inMemory: true)
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        #expect(storeDescription.url == URL(fileURLWithPath: "/dev/null"))
    }

    @Test func ceateWithMOM() throws {
        let momURL = try #require(
            Bundle.module.url(forResource: modelName, withExtension: "momd"))
        let mom = try #require(NSManagedObjectModel(contentsOf: momURL))
        _ = CoreDataContainer(name: modelName, mom: mom, inMemory: true)
    }

    @Test func loadStoreSync() throws {
        container.loadPersistentStores { description, error in
            #expect(error == nil)
        }
        #expect(container.isStoreLoaded)
    }

    @Test func loadStoreAsync() async throws {
        let storeDescription = try #require(
            container.persistentStoreDescriptions.first)
        storeDescription.shouldAddStoreAsynchronously = true

        await withCheckedContinuation { continuation in
            container.loadPersistentStores { description, error in
                #expect(error == nil)
                continuation.resume()
            }
        }
        
        #expect(container.isStoreLoaded)
    }

    @Test func viewContextMergesChanges() throws {
        container.loadPersistentStores { description, error in
            #expect(error == nil)
        }

        #expect(
            container.viewContext.automaticallyMergesChangesFromParent)
    }

    @Test func viewContextName() throws {
        let container = try #require(container)
        container.loadPersistentStores { description, error in
            #expect(error == nil)
        }
        #expect(container.viewContext.name != nil)
    }

    @Test func viewContextMergePolicy() throws {
        container.loadPersistentStores { description, error in
            #expect(error == nil)
        }
        let policy = try #require(
            container.viewContext.mergePolicy as? NSMergePolicy)
        #expect(policy == NSMergePolicy.mergeByPropertyObjectTrump)
    }

    @Test func defaultTransactionAuthor() throws {
        container.loadPersistentStores { description, error in
            #expect(error == nil)
        }
        let author = try #require(container.viewContext.transactionAuthor)
        #expect(author == "app")
    }

    @Test func customTransactionAuthor() throws {
        container.appTransactionAuthorName = "Test"
        container.loadPersistentStores { description, error in
            #expect(error == nil)
        }
        let author = try #require(container.viewContext.transactionAuthor)
        #expect(author == "Test")
    }
}
