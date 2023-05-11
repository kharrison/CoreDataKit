//  Copyright © 2023 Keith Harrison. All rights reserved.
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
import XCTest

final class CoreDataCloudKitContainerTests: XCTestCase {
    private let modelName = "CoreDataKit"
    private var container: CoreDataCloudKitContainer?
    
    override func setUpWithError() throws {
        container = CoreDataCloudKitContainer(name: modelName, bundle: .module, inMemory: true)
    }
    
    override func tearDownWithError() throws {
        container = nil
    }
    
    func testContainerName() throws {
        let container = try XCTUnwrap(container)
        XCTAssertEqual(modelName, container.name)
    }
    
    func testLoadMOM() throws {
        let container = try XCTUnwrap(container)
        let entities = container.managedObjectModel.entities
        XCTAssertEqual(entities.count, 1)
    }
    
    func testDefaultStoreURL() throws {
        let container = try XCTUnwrap(container)
        XCTAssertNotNil(container.storeURL)
    }
       
    func testShouldMigrateStoreAutomatically() throws {
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertTrue(storeDescription.shouldMigrateStoreAutomatically)
    }
    
    func testShouldInferMappingModelAutomatically() throws {
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
        XCTAssertEqual(storeDescription.shouldInferMappingModelAutomatically, true)
    }
    
    func testIsNotReadOnly() throws {
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
        XCTAssertFalse(storeDescription.isReadOnly)
    }
    
    func testShouldAddStoreAsynchronouslyTrueByDefault() throws {
        container = CoreDataCloudKitContainer(name: modelName, bundle: .module)
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
        XCTAssertTrue(storeDescription.shouldAddStoreAsynchronously)
    }
    
    func testShouldAddStoreAsynchronouslyFalseInMemory() throws {
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertFalse(storeDescription.shouldAddStoreAsynchronously)
    }
        
    func testHistoryTrackingKeyTrueByDefault() throws {
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        let historyTrackingOption = try XCTUnwrap(storeDescription.options[NSPersistentHistoryTrackingKey] as? NSNumber)
        XCTAssertTrue(historyTrackingOption.boolValue)
    }

    func testRemoteStoreNotificationTrueByDefault() throws {
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        let remoteChangeOption = try XCTUnwrap(storeDescription.options[NSPersistentStoreRemoteChangeNotificationPostOptionKey] as? NSNumber)
        XCTAssertTrue(remoteChangeOption.boolValue)
    }
    
    func testSyncDisabled() throws {
        let container = CoreDataCloudKitContainer(name: modelName, bundle: .module, syncDisabled: true)
        let privateStore = try XCTUnwrap(container.persistentStoreDescriptions.first)
        let syncStore = try XCTUnwrap(privateStore.copy() as? NSPersistentStoreDescription)
        syncStore.url = CoreDataCloudKitContainer.defaultDirectoryURL().appendingPathComponent("sync.db")
        syncStore.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "test")
        container.persistentStoreDescriptions.append(syncStore)
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
            XCTAssertNil(description.cloudKitContainerOptions)
        }
    }
       
    func testCreateStoreInMemory() throws {
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertEqual(storeDescription.url, URL(fileURLWithPath: "/dev/null"))
    }
    
    func testCreateStoreWithCustomURL() throws {
        let url = FileManager.default.temporaryDirectory
        container = CoreDataCloudKitContainer(name: modelName, bundle: .module, url: url)
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertEqual(storeDescription.url, url)
    }
    
    func testInMemoryStoreOverridesCustomURL() throws {
        let url = FileManager.default.temporaryDirectory
        container = CoreDataCloudKitContainer(name: modelName, bundle: .module, url: url, inMemory: true)
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertEqual(storeDescription.url, URL(fileURLWithPath: "/dev/null"))
    }
    
    func testCeateWithMOM() throws {
        let momURL = try XCTUnwrap(Bundle.module.url(forResource: modelName, withExtension: "momd"))
        let mom = try XCTUnwrap(NSManagedObjectModel(contentsOf: momURL))
        container = CoreDataCloudKitContainer(name: modelName, mom: mom, inMemory: true)
        _ = try XCTUnwrap(container)
    }
    
    func testLoadStoreSync() throws {
        let container = try XCTUnwrap(container)
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
    }
    
    func testLoadStoreAsync() throws {
        let container = try XCTUnwrap(container)
        let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
        storeDescription.shouldAddStoreAsynchronously = true
        
        let expect = expectation(description: "Store loaded")
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testViewContextMergesChanges() throws {
        let container = try XCTUnwrap(container)
        let expect = expectation(description: "Store loaded")
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(container.viewContext.automaticallyMergesChangesFromParent)
    }
    
    func testViewContextName() throws {
        let container = try XCTUnwrap(container)
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        XCTAssertNotNil(container.viewContext.name)
    }
    
    func testViewContextMergePolicy() throws {
        let container = try XCTUnwrap(container)
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        let policy = try XCTUnwrap(container.viewContext.mergePolicy as? NSMergePolicy)
        XCTAssertEqual(policy, NSMergePolicy.mergeByPropertyObjectTrump)
    }
    
    func testDefaultTransactionAuthor() throws {
        let container = try XCTUnwrap(container)
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        let author = try XCTUnwrap(container.viewContext.transactionAuthor)
        XCTAssertEqual(author, "app")
    }
    
    func testCustomTransactionAuthor() throws {
        let container = try XCTUnwrap(container)
        container.appTransactionAuthorName = "Test"
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        let author = try XCTUnwrap(container.viewContext.transactionAuthor)
        XCTAssertEqual(author, "Test")
    }
}
