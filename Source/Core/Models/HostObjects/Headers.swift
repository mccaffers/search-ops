// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
