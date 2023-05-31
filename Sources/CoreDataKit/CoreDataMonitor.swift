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

import CloudKit
import CoreData
import Foundation
import Network

/// Core Data Monitor - Monitor the status of Core Data
/// CloudKit sync.
///
/// This is an Observable Object you can use to monitor
/// the status of the persistent CloudKit container.
public final class CoreDataMonitor: ObservableObject {
    /// CloudKit Account Status.
    /// The availability of the user's iCloud account.
    @Published public private(set) var accountStatus: CKAccountStatus?
    
    /// CloudKit Account Error.
    @Published public private(set) var accountError: Error?
    
    /// Network path. The network availability status and
    /// capabilities of the available interfaces.
    @Published public private(set) var networkPath: NWPath?
    
    /// Last setup activity of the persistent CloudKit container,
    @Published public private(set) var lastSetup: NSPersistentCloudKitContainer.Event?
    
    /// Last import activity of the persistent CloudKit container,
    @Published public private(set) var lastImport: NSPersistentCloudKitContainer.Event?
    
    /// Last export activity of the persistent CloudKit container,
    @Published public private(set) var lastExport: NSPersistentCloudKitContainer.Event?

    /// Is the container syncing? This is true if the user's
    /// iCloud account is available, the network status is
    /// satisfied and there are no errors from the last
    /// setup, import or export CloudKit activities.
    public var syncing: Bool {
        (accountStatus == .available) &&
        (networkPath?.status == .satisfied) &&
        (lastSetup?.error == nil) &&
        (lastImport?.error == nil) &&
        (lastExport?.error == nil)
    }
    
    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "NWPathMonitor")
    
    /// Create a Core Data Monitor object.
    /// - Parameters:
    ///   - accountStatus: CloudKit Account status. Default is `nil`
    ///   - accountError: CloudKit Account error. Default is `nil`.
    ///   - active: Is the monitoring active or disabled. Default is `true`.
    ///
    ///   - Note: For normal use call this method with the default options.
    ///     Disable the active monitoring for unit testing and previews.
    public init(accountStatus: CKAccountStatus? = nil, accountError: Error? = nil, active: Bool = true) {
        self.accountStatus = accountStatus
        self.accountError = accountError
        
        if active {
            enableAccountMonitor()
            enablePathMonitor()
            enableEventMonitoring()
        }
    }
    
    private func enableAccountMonitor() {
        updateAccountStatus()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accountStatusChanged(_:)),
                                               name: .CKAccountChanged,
                                               object: nil)
    }
    
    @objc
    private func accountStatusChanged(_ notification: Notification) {
        updateAccountStatus()
    }
    
    private func updateAccountStatus() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                self.accountStatus = status
                self.accountError = error
            }
        }
    }
    
    private func enablePathMonitor() {
        pathMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.networkPath = path
            }
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }
    
    private func enableEventMonitoring() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(eventChanged(_:)),
                                               name: NSPersistentCloudKitContainer.eventChangedNotification,
                                               object: nil)
    }
    
    @objc
    private func eventChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let event = userInfo[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        DispatchQueue.main.async {
            switch event.type {
            case .setup: self.lastSetup = event
            case .import: self.lastImport = event
            case .export: self.lastExport = event
            @unknown default:
                assertionFailure("NSPersistentCloudKitContainer.Event.type unknown")
            }
        }
    }
}
