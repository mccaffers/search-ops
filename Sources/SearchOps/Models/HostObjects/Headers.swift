// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class Headers : Object  {
    @Persisted public var id: UUID = UUID()
    @Persisted public var header: String = ""
    @Persisted public var value: String = ""
    @Persisted public var focusedIndexHeader: Double = 0
    @Persisted public var focusedIndexValue: Double = 0
}
