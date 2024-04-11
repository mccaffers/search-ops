// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class DateToolsTests: XCTestCase {
  

  func testdateString() throws {
    let currentDate = Date()
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"

    let stringInput = dateFormatter.string(from: currentDate)
    
    let stringOutput = DateTools.dateString(currentDate)
    XCTAssert(stringInput == stringOutput, "Date function")
    
  }
  
  func testdateRange() throws {
    
    // One minute test (in seconds)
    let oneMinRange = RelativeRangeFilter(period: .Minutes, value: 1)
    let getTimeForOneMin = oneMinRange.GetFromTime()
    let timeMinusOneMin = Date.now - 60
    XCTAssertEqual(getTimeForOneMin, timeMinusOneMin)
    
    // One hour test (in seconds)
    let oneHourRange = RelativeRangeFilter(period: .Hours, value: 1)
    let getTimeForOneHour = oneHourRange.GetFromTime()
    let timeMinusOneHour = Date.now - 3600
    XCTAssertEqual(getTimeForOneHour, timeMinusOneHour)
    
    // One day test (in seconds)
    let oneDayRange = RelativeRangeFilter(period: .Days, value: 1)
    let getTimeForOneDay = oneDayRange.GetFromTime()
    let timeMinusOneDay = Date.now - 86400
    XCTAssertEqual(getTimeForOneDay, timeMinusOneDay)
    
  }
  
  
}
