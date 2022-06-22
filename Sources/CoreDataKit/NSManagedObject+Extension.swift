//  Copyright © 2022 Keith Harrison. All rights reserved.
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

extension NSManagedObject {
    /// Create a new managed object, inserting it into the
    /// specified managed object context.
    ///
    /// This method calls the designated initializer
    /// `init(entity:insertInto:)` using the class name to create
    /// the entity description. This avoids a problem, often seen
    /// in unit tests, where the convenience initializer
    /// `init(context:)` generates a warning that multiple
    /// `NSEntityDescriptions` claim the `NSManagedObject` subclass
    /// when the managed object model is loaded more than once.
    ///
    /// - Note: This method assumes the class name matches the
    ///   entity name in the model. It will crash if the entity
    ///   cannot be found in the managed object model.
    ///
    /// - Parameter context: The context to insert the new object
    ///   into.
    public convenience init(insertInto context: NSManagedObjectContext) {
        let entityName = String(describing: type(of: self))
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            fatalError("\(entityName) not found")
        }
        self.init(entity: entity, insertInto: context)
    }
}
