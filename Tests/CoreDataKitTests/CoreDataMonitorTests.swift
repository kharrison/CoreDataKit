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

import CoreDataKit
import XCTest

final class CoreDataMonitorTests: XCTestCase {
    func testAccountStatusPublished() {
        let monitor = CoreDataMonitor(accountStatus: .available, active: false)
        
        let expectation = expectation(description: "Value published")
        let cancellable = monitor.$accountStatus.sink { status in
            XCTAssertEqual(status, .available)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
    }
    
    func testAccountErrorPublished() {
        let error = NSError(domain: NSCocoaErrorDomain, code: -1)
        let monitor = CoreDataMonitor(accountError: error, active: false)
        
        let expectation = expectation(description: "Value published")
        let cancellable = monitor.$accountError.sink { value in
            XCTAssertEqual(value as? NSError, error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
    }
    
    func testNetworkStatusPublished() {
        let monitor = CoreDataMonitor(active: false)
        
        let expectation = expectation(description: "Value published")
        let cancellable = monitor.$networkPath.sink { path in
            XCTAssertNil(path)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
    }
    
    func testSetupEventPublished() {
        let monitor = CoreDataMonitor(active: false)
        
        let expectation = expectation(description: "Value published")
        let cancellable = monitor.$lastSetup.sink { event in
            XCTAssertNil(event)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
    }

    func testImportEventPublished() {
        let monitor = CoreDataMonitor(active: false)
        
        let expectation = expectation(description: "Value published")
        let cancellable = monitor.$lastImport.sink { event in
            XCTAssertNil(event)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
    }

    func testExportEventPublished() {
        let monitor = CoreDataMonitor(active: false)
        
        let expectation = expectation(description: "Value published")
        let cancellable = monitor.$lastExport.sink { event in
            XCTAssertNil(event)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
    }
}
