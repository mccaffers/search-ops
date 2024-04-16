// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class DateToolsTests: XCTestCase {
  
  private let calendar = Calendar.current

  func testdateString() throws {
    let currentDate = Date()
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"

    let stringInput = dateFormatter.string(from: currentDate)
    
    let stringOutput = DateTools.dateString(currentDate)
    XCTAssert(stringInput == stringOutput, "Date function")
    
  }
  
  func testdateRangeMinutes() throws {
    
    // One minute test (in seconds)
    let oneMinRange = RelativeRangeFilter(period: .Minutes, value: 1)
    let getTimeForOneMin = oneMinRange.GetFromTime()
    let minFromFilter = calendar.component(.minute, from: getTimeForOneMin)
    
    let timeMinusOneMin = Date.now - 60
    let minFromNow = calendar.component(.minute, from: timeMinusOneMin)
    XCTAssertEqual(minFromFilter, minFromNow)
  }
  
  func testdateRangeHours() throws {
    // One hour test (in seconds)
    let oneHourRange = RelativeRangeFilter(period: .Hours, value: 1)
    let getTimeForOneHour = oneHourRange.GetFromTime()
    let getHourFromFilter = calendar.component(.hour, from: getTimeForOneHour)
    
    let timeMinusOneHour = Date.now - 3600
    let getHourFromNow = calendar.component(.hour, from: timeMinusOneHour)
    XCTAssertEqual(getHourFromFilter, getHourFromNow)
    
  }
  
  func testdateRangeDays() throws {
    // One day test (in seconds)
    let oneDayRange = RelativeRangeFilter(period: .Days, value: 1)
    let getTimeForOneDay = oneDayRange.GetFromTime()
    let getDayFromFilter = calendar.component(.day, from: getTimeForOneDay)
    
    let timeMinusOneDay = Date.now - 86400
    let getDayFromNow = calendar.component(.day, from: timeMinusOneDay)
    XCTAssertEqual(getDayFromFilter, getDayFromNow)
    
  }
  
  
}
