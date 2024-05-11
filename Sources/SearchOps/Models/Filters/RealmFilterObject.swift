// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13, *)
@available(iOS 15.0, *)
public class RealmFilterObject: Object {
    
    @Persisted(primaryKey: true) public var id: UUID = UUID()
    @Persisted public var query: QueryObject? = nil
    @Persisted public var dateField: RealmSquashedFieldsArray?
    @Persisted public var relativeRange: RealmRelativeRangeFilter?
    @Persisted public var absoluteRange: RealmAbsoluteDateRangeObject?
    @Persisted public var date: Date = Date.now
    @Persisted public var count: Int = 1
    
}
