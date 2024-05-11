// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 10.13, *)
@available(iOS 15.0, *)

public class RealmRelativeRangeFilter : EmbeddedObject {
    @Persisted public var period: SearchDateTimePeriods = SearchDateTimePeriods.Minutes
    @Persisted public var value: Double = 0.0
}
