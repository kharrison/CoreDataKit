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

public protocol ManagedObject: NSFetchRequestResult {
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    static var fetchRequest: NSFetchRequest<Self> { get }
    static var sortedFetchRequest: NSFetchRequest<Self> { get }
}

extension ManagedObject {
    public static var defaultSortDescriptors: [NSSortDescriptor] { [] }
    
    public static var fetchRequest: NSFetchRequest<Self> {
        NSFetchRequest<Self>(entityName: entityName)
    }
    
    public static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = fetchRequest
        request.sortDescriptors = defaultSortDescriptors
        return request
    }
}

extension ManagedObject where Self: NSManagedObject {
    public typealias configureRequest = (NSFetchRequest<Self>) -> Void
    
    public static func countRequest(_ context: NSManagedObjectContext, configure: configureRequest? = nil) -> Int {
        let request = fetchRequest
        if let configure = configure { configure(request) }
        let count = try? context.count(for: request)
        return count ?? 0
    }
    
    public static func fetch(_ context: NSManagedObjectContext, configure: configureRequest? = nil) -> Result<[Self], Error> {
        let request = fetchRequest
        if let configure = configure { configure(request) }
        return Result { try context.fetch(request) }
    }
    
    public static func fetchOrCreate(_ context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self {
        let result = fetch(context) { request in
            request.predicate = predicate
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
        }

        guard case let .success(objects) = result,
              let object = objects.first else {
            return Self(context: context)
        }
        
        return object
    }
}
