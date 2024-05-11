// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

class DateToolsTests: XCTestCase {
  
  private let calendar = Calendar.current
  
  func testCalculateSecondsForSeconds() {
    XCTAssertEqual(DateTools.calculateSecondsByPeriod(value: 1, period: .Seconds), 1)
  }
  
  func testCalculateSecondsForMinutes() {
    XCTAssertEqual(DateTools.calculateSecondsByPeriod(value: 1, period: .Minutes), 60)
  }
  
  func testCalculateSecondsForHours() {
    XCTAssertEqual(DateTools.calculateSecondsByPeriod(value: 1, period: .Hours), 3600)
  }
  
  func testCalculateSecondsForDays() {
    XCTAssertEqual(DateTools.calculateSecondsByPeriod(value: 1, period: .Days), 86400)
  }
  
  func testCalculateSecondsForWeeks() {
    XCTAssertEqual(DateTools.calculateSecondsByPeriod(value: 1, period: .Weeks), 604800)
  }
  
  func testCalculateSecondsForMonths() {
    XCTAssertEqual(DateTools.calculateSecondsByPeriod(value: 1, period: .Months), 2628000)
  }
  
  func testCalculateSecondsForYears() {
    XCTAssertEqual(DateTools.calculateSecondsByPeriod(value: 1, period: .Years), 31536000)
  }
  
  // Tests for buildDate and related functions
  func testBuildDateReturnsCorrectFormat() {
    let testDate = "2020-01-01T12:00:00.000+0000"
    XCTAssertEqual(DateTools.buildDate(input: testDate), "1/01/20 12:00:00")
  }
  
  func testBuildDateLargeReturnsCorrectFormat() {
    let testDate = "2020-01-01T12:00:00.000+0000"
    XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Jan 1, 2020 12:00:00")
  }
  
  func testBuildDateWithDate() {
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d MMM yyyy HH:mm:ss.SSSS"
    let expectedFormat = dateFormatter.string(from: date)
    XCTAssertEqual(DateTools.buildDateLarge(input: date), expectedFormat)
  }
  
  func testGetDate() {
    let testDateStr = "2020-01-01T12:00:00.000+0000"
    XCTAssertNotNil(DateTools.getDate(input: testDateStr))
  }
  
  func testDateString() {
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
    let expectedFormat = dateFormatter.string(from: date)
    XCTAssertEqual(DateTools.dateString(date), expectedFormat)
  }
  
  func testGetDateString() {
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd / MM / yyyy"
    let expectedFormat = dateFormatter.string(from: date)
    XCTAssertEqual(DateTools.getDateString(date), expectedFormat)
  }
  
  func testGetHourString() {
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss a"
    let expectedFormat = dateFormatter.string(from: date)
    XCTAssertEqual(DateTools.getHourString(date), expectedFormat)
  }
  
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
  
  func testEjectRealmObject() {
    let filter = RelativeRangeFilter(period: .Days, value: 2.0)
    let realmObj = filter.ejectRealmObject()
    XCTAssertEqual(realmObj.period, filter.period, "Realm object period should match the filter's period.")
    XCTAssertEqual(realmObj.value, filter.value, "Realm object value should match the filter's value.")
  }
}
