// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
@available(iOS 15.0, *)

public class RealmAbsoluteDateRangeObject : EmbeddedObject {
    
    @Persisted public var active: Bool = false
    @Persisted public var from: Date = Date.now
    @Persisted public var to: Date = Date.now

}

