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
import XCTest

final class CoreDataContainerTests: XCTestCase {
    private let modelName = "CoreDataKit"
    private var container: CoreDataContainer!
  
    override func setUpWithError() throws {
        container = CoreDataContainer(name: modelName, bundle: .module, inMemory: true)
    }
    
    override func tearDownWithError() throws {
        container = nil
    }
       
    func testContainerName() throws {
        XCTAssertEqual(modelName, container.name)
    }

    func testLoadMOM() throws {
        let entities = container.managedObjectModel.entities
        XCTAssertEqual(entities.count, 1)
    }

    func testDefaultStoreURL() throws {
        XCTAssertNotNil(container.storeURL)
    }

    func testStoreNotLoaded() throws {
        XCTAssertFalse(container.isStoreLoaded)
    }
    
    func testShouldMigrateStoreAutomatically() throws {
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertTrue(storeDescription.shouldMigrateStoreAutomatically)
    }
    
    func testShouldInferMappingModelAutomatically() throws {
        let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
        XCTAssertEqual(storeDescription.shouldInferMappingModelAutomatically, true)
    }
    
    func testIsNotReadOnly() throws {
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertFalse(storeDescription.isReadOnly)
    }
    
    func testShouldAddStoreAsynchronouslyTrueByDefault() throws {
        container = CoreDataContainer(name: modelName, bundle: .module)
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertTrue(storeDescription.shouldAddStoreAsynchronously)
    }

    func testShouldAddStoreAsynchronouslyFalseInMemory() throws {
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertFalse(storeDescription.shouldAddStoreAsynchronously)
    }

    func testCreateStoreInMemory() throws {
        let storeDescription = try XCTUnwrap( container.persistentStoreDescriptions.first)
        XCTAssertEqual(storeDescription.url, URL(fileURLWithPath: "/dev/null"))
    }

    func testLoadStoreSync() throws {
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(container.isStoreLoaded)
    }

    func testLoadStoreAsync() throws {
        let storeDescription = try XCTUnwrap(container.persistentStoreDescriptions.first)
        storeDescription.shouldAddStoreAsynchronously = true

        let expect = expectation(description: "Store loaded")
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
            expect.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(container.isStoreLoaded)
    }
       
    func testViewContextMergesChanges() throws {
        let expect = expectation(description: "Store loaded")
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(container.viewContext.automaticallyMergesChangesFromParent)
    }
    
    func testViewContextName() throws {
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        XCTAssertNotNil(container.viewContext.name)
    }
}
