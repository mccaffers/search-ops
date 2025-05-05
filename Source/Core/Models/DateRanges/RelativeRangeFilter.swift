// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
  
  public func GeneratePrettyTimeString() -> String {
    var myString = "Last "
    if value == 1 {
      
      myString += sliceString(str: period.rawValue, start: 0, end: period.rawValue.count-1)
      
      
    } else {
      myString += value.string + " " + period.rawValue
    }
    
//    myString += "\n"
    
    return myString
  }
  
  public func ejectRealmObject() -> RealmRelativeRangeFilter {
    let realmObj = RealmRelativeRangeFilter()
    realmObj.period = self.period
    realmObj.value = self.value
    return realmObj
  }
  
  func sliceString(str: String, start: Int, end: Int) -> String {
      let data = Array(str)
      return String(data[start..<end])
  }

  
}
