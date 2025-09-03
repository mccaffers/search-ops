// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

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

     
     // MARK: - ISO 8601 Format Tests
     func testBuildDateLargeWithISO8601BasicFormat() {
         let testDate = "2025-09-03T07:37:01"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Sep 3, 2025 07:37:01")
     }
     
     func testBuildDateLargeWithISO8601WithMilliseconds() {
         let testDate = "2023-12-25T15:30:45.123"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Dec 25, 2023 15:30:45")
     }
          
     func testBuildDateLargeWithISO8601WithMicroseconds() {
         let testDate = "2024-03-10T14:22:33.456789"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Mar 10, 2024 14:22:33")
     }
     
     // MARK: - Space-Separated Format Tests
     func testBuildDateLargeWithSpaceSeparatedFormat() {
         let testDate = "2024-08-20 11:15:30"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Aug 20, 2024 11:15:30")
     }
     
     func testBuildDateLargeWithSpaceSeparatedWithMilliseconds() {
         let testDate = "2024-11-01 16:45:22.789"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Nov 1, 2024 16:45:22")
     }
         
     // MARK: - Date-Only Format Tests
     func testBuildDateLargeWithDateOnly() {
         let testDate = "2024-07-04"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Jul 4, 2024 00:00:00")
     }
     
     // MARK: - Human-Readable Format Tests
     func testBuildDateLargeWithHumanReadableFormat() {
         let testDate = "Mar 15, 2024 13:45:30"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Mar 15, 2024 13:45:30")
     }
     
     // MARK: - Edge Cases and Invalid Formats
     func testBuildDateLargeWithInvalidDateReturnsEmptyString() {
         let testDate = "invalid-date-format"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "")
     }
     
     func testBuildDateLargeWithEmptyStringReturnsEmptyString() {
         let testDate = ""
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "")
     }
     
     func testBuildDateLargeWithPartialDateReturnsEmptyString() {
         let testDate = "2024-13-45"  // Invalid month
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "")
     }
     
     // MARK: - Date Object Input Tests
     func testBuildDateLargeWithDateObject() {
         let calendar = Calendar.current
         let dateComponents = DateComponents(year: 2024, month: 5, day: 20, hour: 10, minute: 30, second: 45, nanosecond: 123456789)
         let testDate = calendar.date(from: dateComponents)!
         let result = DateTools.buildDateLarge(input: testDate)
         XCTAssertTrue(result.contains("20 May 2024 10:30:45"))
     }
     
     // MARK: - Boundary Tests
     func testBuildDateLargeWithLeapYearDate() {
         let testDate = "2024-02-29T12:00:00"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Feb 29, 2024 12:00:00")
     }
     
     func testBuildDateLargeWithNewYearDate() {
         let testDate = "2024-01-01T00:00:01"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Jan 1, 2024 00:00:01")
     }
     
     func testBuildDateLargeWithEndOfYearDate() {
         let testDate = "2024-12-31T23:59:59"
         XCTAssertEqual(DateTools.buildDateLarge(input: testDate), "Dec 31, 2024 23:59:59")
     }
     
     // MARK: - getDate Function Direct Tests
     func testGetDateWithVariousFormats() {
         let testCases = [
             "2025-09-03T07:37:01",
             "2024-12-25T15:30:45.123",
             "2024-06-15 09:45:30",
             "2024-07-04",
             "2023-11-11T11:11:11.111Z"
         ]
         
         for testCase in testCases {
             let result = DateTools.getDate(input: testCase)
             XCTAssertNotNil(result, "Failed to parse date: \(testCase)")
         }
     }
     
     func testGetDateWithInvalidFormatsReturnsNil() {
         let invalidCases = [
             "not-a-date",
             "2024-13-01",  // Invalid month
             "2024-02-30",  // Invalid day for February
             "25:00:00",    // Invalid hour
             ""
         ]
         
         for testCase in invalidCases {
             let result = DateTools.getDate(input: testCase)
             XCTAssertNil(result, "Should return nil for invalid date: \(testCase)")
         }
     }
}
