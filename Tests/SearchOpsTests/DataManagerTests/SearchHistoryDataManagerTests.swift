// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Foundation
import RealmSwift

@testable import SearchOps
@available(macOS 13.0, *)
@available(iOS 15.0, *)

class SearchHistoryDataManagerTests: XCTestCase {
  
  var dataManager: SearchHistoryDataManager!
  
  @MainActor
  override func setUp() {
    super.setUp()
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    _ = RealmManager().getRealm(inMemory: true)
    dataManager = SearchHistoryDataManager()
  }
  
  override func tearDown() {
    dataManager = nil
    super.tearDown()
  }
  @MainActor
  func testStaticList() async {
    // Given
    let realmEvent1 = RealmSearchEvent()
    realmEvent1.host = UUID()
    realmEvent1.index = "index1"
    realmEvent1.date = Date(timeIntervalSince1970: 1000)
    
    let realmEvent2 = RealmSearchEvent()
    realmEvent2.host = UUID()
    realmEvent2.index = "index2"
    realmEvent2.date = Date(timeIntervalSince1970: 2000)
    
    dataManager.items = [realmEvent1, realmEvent2]
    
    // When
    let result = dataManager.staticList()
    
    // Then
    XCTAssertEqual(result.count, 2)
    XCTAssertEqual(result[0].index, "index1")
    XCTAssertEqual(result[0].date, Date(timeIntervalSince1970: 1000))
    XCTAssertEqual(result[1].index, "index2")
    XCTAssertEqual(result[1].date, Date(timeIntervalSince1970: 2000))
  }
  @MainActor
  func testAreDatesSameDay() {
    // Test same day, different times
    let date1 = Date(timeIntervalSince1970: 1625097600) // July 1, 2021 00:00:00 UTC
    let date2 = Date(timeIntervalSince1970: 1625140800) // July 1, 2021 12:00:00 UTC
    XCTAssertTrue(dataManager.areDatesSameDay(date1: date1, date2: date2))
    
    // Test different days
    let date3 = Date(timeIntervalSince1970: 1625184000) // July 2, 2021 00:00:00 UTC
    XCTAssertFalse(dataManager.areDatesSameDay(date1: date1, date2: date3))
    
    // Test same day, different years
    let date4 = Date(timeIntervalSince1970: 1656633600) // July 1, 2022 00:00:00 UTC
    XCTAssertFalse(dataManager.areDatesSameDay(date1: date1, date2: date4))
    
    // Test edge case: end of day and start of next day
    let date5 = Date(timeIntervalSince1970: 1625183999) // July 1, 2021 23:59:59 UTC
    let date6 = Date(timeIntervalSince1970: 1625184000) // July 2, 2021 00:00:00 UTC
    XCTAssertFalse(dataManager.areDatesSameDay(date1: date5, date2: date6))
  }
  
  @MainActor
  func testGroupByDate() {
    // Given
    let date1 = Date(timeIntervalSince1970: 1625097600) // July 1, 2021 00:00:00 UTC
    let date2 = Date(timeIntervalSince1970: 1625140800) // July 1, 2021 12:00:00 UTC
    let date3 = Date(timeIntervalSince1970: 1625184000) // July 2, 2021 00:00:00 UTC
    
    let event1 = createSearchEvent(date: date1, index: "index1")
    let event2 = createSearchEvent(date: date2, index: "index2")
    let event3 = createSearchEvent(date: date3, index: "index3")
    
    // Simulate the orderedByDate() method
    dataManager.items = [
      createRealmSearchEvent(from: event3),
      createRealmSearchEvent(from: event2),
      createRealmSearchEvent(from: event1)
    ]
    
    // When
    let result = dataManager.groupByDate()
    
    // Then
    XCTAssertEqual(result.keys.count, 2) // Two unique dates
    
    let calendar = Calendar.current
    let july1 = calendar.startOfDay(for: date1)
    let july2 = calendar.startOfDay(for: date3)
    
    XCTAssertNotNil(result[july1])
    XCTAssertNotNil(result[july2])
    
    XCTAssertEqual(result[july1]?.count, 2)
    XCTAssertEqual(result[july2]?.count, 1)
    
    XCTAssertEqual(result[july1]?[0].index, "index2")
    XCTAssertEqual(result[july1]?[1].index, "index1")
    XCTAssertEqual(result[july2]?[0].index, "index3")
  }
  
  private func createSearchEvent(date: Date, index: String) -> SearchEvent {
    let event = SearchEvent()
    event.date = date
    event.index = index
    return event
  }
  
  private func createRealmSearchEvent(from event: SearchEvent) -> RealmSearchEvent {
    let realmEvent = RealmSearchEvent()
    realmEvent.date = event.date
    realmEvent.index = event.index
    return realmEvent
  }
}
