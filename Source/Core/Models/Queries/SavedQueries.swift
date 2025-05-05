// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

// TODO UNUSUED
public class SavedQueries : Object  {
    @Persisted(primaryKey: true) public var id: UUID = UUID()
    @Persisted public var builtInQuery: BuiltInQueries = BuiltInQueries.Indexes
    @Persisted public var hostID: UUID?
    @Persisted public var detachedID: UUID?
    
    public func generateCopy() -> SavedQueries {
        
        let copy = SavedQueries()
        copy.detachedID = self.id
        copy.builtInQuery = self.builtInQuery
        copy.hostID = self.hostID
        
        return copy
    }
}
