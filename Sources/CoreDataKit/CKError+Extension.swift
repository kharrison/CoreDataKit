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

extension CKError {
    /// A description of the CloudKit error code.
    public var userMessage: String {
        switch code {
        case .internalError:
            return "Internal error. CloudKit has encountered a nonrecoverable error"
            
        case .partialFailure:
            return "Partial failure."
            
        case .networkUnavailable:
            return "Network unavailable."
            
        case .networkFailure:
            return "Network Failure. The network is available but CloudKit is inaccessible."
            
        case .badContainer:
            return "Bad container. Unknown or unauthorized container."
            
        case .serviceUnavailable:
            return "CloudKit service is unavailable."
            
        case .requestRateLimited:
            return "Request rate limited."
            
        case .missingEntitlement:
            return "App is missing entitlement."
            
        case .notAuthenticated:
            return "User is not authenticated. Try logging in."
            
        case .permissionFailure:
            return "User does not have permission to save or fetch data"
            
        case .unknownItem:
            return "Unknown item. The specified record doesn't exist."
            
        case .invalidArguments:
            return "Invalid arguments. Bad client request."
            
        case .resultsTruncated:
            return "Results truncated."
            
        case .serverRecordChanged:
            return "Server record changed. The server's version of the record is newer than the local version."
            
        case .serverRejectedRequest:
            return "Server rejected request."
            
        case .assetFileNotFound:
            return "Asset file not found."
            
        case .assetFileModified:
            return "Asset file modified during save."
            
        case .incompatibleVersion:
            return "Incompatible verion. Current app version is older than the oldest allowed version."
            
        case .constraintViolation:
            return "Constraint violation. Server rejected request because of a unique constraint violation."
            
        case .operationCancelled:
            return "Operation cancelled."
            
        case .changeTokenExpired:
            return "Change token expired. Client must re-sync from scratch."
            
        case .batchRequestFailed:
            return "Batch request failed due to failure of one or more items in the batch failing."
            
        case .zoneBusy:
            return "Zone busy. The server is too busy to handle the record zone operation."
            
        case .badDatabase:
            return "Bad database. Maybe caused by attempting to modify zones in the public database."
            
        case .quotaExceeded:
            return "iCloud storage quota exceeded."
            
        case .zoneNotFound:
            return "Zone not found."
            
        case .limitExceeded:
            return "Limit exceeded. The request's size exceeds the server limits."
            
        case .userDeletedZone:
            return "User deleted zone using the Settings app."
            
        case .tooManyParticipants:
            return "Share has too many participants."
            
        case .alreadyShared:
            return "Already shared. A record can exist in only a single share at a time."
            
        case .referenceViolation:
            return "Reference violation. CloudKit can't find the target of a reference."
            
        case .managedAccountRestricted:
            return "Managed account restricted. CloudKit access restricted for this account."
            
        case .participantMayNeedVerification:
            return "Participant may need verification. User isn't a participant of the share."
            
        case .serverResponseLost:
            return "Server response lost. CloudKit was unable to maintain the network connection."
            
        case .assetNotAvailable:
            return "Asset not available or you do not have permission to open the file."
            
        case .accountTemporarilyUnavailable:
            return "Account temporarily unavailable. User action may be required. User should check their iCloud account in the Settings app."
            
        @unknown default: return localizedDescription
        }
    }
}
