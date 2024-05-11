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

public class RelativeRangeFilter : ObservableObject {
    
    public init(period: SearchDateTimePeriods = SearchDateTimePeriods.Minutes, value: Double = 0.0) {
        self.period = period
        self.value = value
    }
    
    
    @Published public var period: SearchDateTimePeriods = SearchDateTimePeriods.Minutes
    @Published public var value: Double = 0.0
    
    public func GetFromTime() -> Date {
      let seconds = DateTools.calculateSecondsByPeriod(value: self.value, period: self.period)
      return Date.now - seconds
    }
    
    public func ejectRealmObject() -> RealmRelativeRangeFilter {
        let realmObj = RealmRelativeRangeFilter()
        realmObj.period = self.period
        realmObj.value = self.value
        return realmObj
    }
}
