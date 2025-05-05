// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13, *)
@available(iOS 15, *)
public class LogFilter : EmbeddedObject {
  @Persisted public var query: QueryObject? = nil
  @Persisted public var dateField: RealmSquashedFieldsArray?
  @Persisted public var relativeRange: RealmRelativeRangeFilter?
  @Persisted public var absoluteRange: RealmAbsoluteDateRangeObject?
}
