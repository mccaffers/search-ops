// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 10.13, *)
@available(iOS 15.0, *)

public class RealmRelativeRangeFilter : EmbeddedObject {
    @Persisted public var period: SearchDateTimePeriods = SearchDateTimePeriods.Minutes
    @Persisted public var value: Double = 0.0
  
  public func copy() -> RealmRelativeRangeFilter {
    let relativeRange = RealmRelativeRangeFilter()
    relativeRange.period = self.period
    relativeRange.value = self.value
    return relativeRange
  }
  public func isEqual(object: RealmRelativeRangeFilter?) -> Bool {
    guard self.period == object?.period else { return false }
    guard self.value == object?.value else { return false }
    return true
  }
}
