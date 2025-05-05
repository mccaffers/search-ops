// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Foundation
import RealmSwift

@testable import Search_Ops

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
  
  // Helper function to create a RealmSearchEvent
  func createFullSearchEvent(host: UUID, index: String, query: String, dateField: String? = nil, relativeRange: (period: SearchDateTimePeriods, value: Double)? = nil, absoluteRange: (from: Date, to: Date)? = nil) -> RealmSearchEvent {
    let event = RealmSearchEvent()
    event.host = host
    event.index = index
    event.query = QueryObject()
    event.query?.values.append(QueryFilterObject(string: query))
    
    if let dateField = dateField {
      event.dateField = RealmSquashedFieldsArray()
      event.dateField?.squashedString = dateField
    }
    
    if let relativeRange = relativeRange {
      event.relativeRange = RealmRelativeRangeFilter()
      event.relativeRange?.period = relativeRange.period
      event.relativeRange?.value = relativeRange.value
    }
    
    if let absoluteRange = absoluteRange {
      event.absoluteRange = RealmAbsoluteDateRangeObject()
      event.absoluteRange?.from = absoluteRange.from
      event.absoluteRange?.to = absoluteRange.to
    }
    
    return event
  }
  
  @MainActor
  func testCheckIfEntryExistsWithMatchingEntry() throws {
    
    let existingEntry = RealmSearchEvent()
    existingEntry.host = UUID()
    existingEntry.index = "test-index"
    existingEntry.query = QueryObject()
    existingEntry.query?.values.append(QueryFilterObject(string: "test query"))
    existingEntry.dateField = RealmSquashedFieldsArray()
    existingEntry.dateField?.squashedString = "test-date-field"
    
    dataManager.addNew(item: existingEntry)
    
    let newEntry = RealmSearchEvent()
    newEntry.host = existingEntry.host
    newEntry.index = existingEntry.index
    newEntry.query = QueryObject()
    newEntry.query?.values.append(QueryFilterObject(string: "test query"))
    newEntry.dateField = RealmSquashedFieldsArray()
    newEntry.dateField?.squashedString = "test-date-field"
    
    dataManager.refresh()
    
    let result = dataManager.checkIfEntryExists(newEntry: newEntry)
    
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.host, existingEntry.host)
    XCTAssertEqual(result?.index, existingEntry.index)
    
    let outcome = dataManager.areEntriesMatching(currentItem: existingEntry,
                                                 newEntry: newEntry)
    
    XCTAssertTrue(outcome)
  }
  
  @MainActor
  func testCheckIfEntryExistsWithNonMatchingEntry() throws {
    let existingEntry = RealmSearchEvent()
    existingEntry.host = UUID()
    existingEntry.index = "test-index"
    
    dataManager.addNew(item: existingEntry)
    
    let newEntry = RealmSearchEvent()
    newEntry.host = UUID() // Different host
    newEntry.index = "different-index"
    
    dataManager.refresh()
    
    let result = dataManager.checkIfEntryExists(newEntry: newEntry)
    
    XCTAssertNil(result)
    
    let outcome = dataManager.areEntriesMatching(currentItem: existingEntry,
                                                 newEntry: newEntry)
    
    XCTAssertFalse(outcome)
  }
  
  @MainActor
  func testCheckIfEntryExistsWithDifferentQuery() throws {
    let existingEntry = RealmSearchEvent()
    existingEntry.host = UUID()
    existingEntry.index = "test-index"
    existingEntry.query = QueryObject()
    existingEntry.query?.values.append(QueryFilterObject(string: "test query"))
    
    dataManager.addNew(item: existingEntry)
    
    let newEntry = RealmSearchEvent()
    newEntry.host = existingEntry.host
    newEntry.index = existingEntry.index
    newEntry.query = QueryObject()
    newEntry.query?.values.append(QueryFilterObject(string: "different query"))
    
    dataManager.refresh()
    
    let result = dataManager.checkIfEntryExists(newEntry: newEntry)
    
    XCTAssertNil(result)
    
    let outcome = dataManager.areEntriesMatching(currentItem: existingEntry,
                                                 newEntry: newEntry)
    
    XCTAssertFalse(outcome)
  }
  
  @MainActor
  func testCheckIfEntryExistsWithSameQuery() throws {
    let existingEntry = RealmSearchEvent()
    existingEntry.host = UUID()
    existingEntry.index = "test-index"
    existingEntry.query = QueryObject()
    existingEntry.query?.values.append(QueryFilterObject(string: "test query"))
    
    dataManager.addNew(item: existingEntry)
    
    let newEntry = RealmSearchEvent()
    newEntry.host = existingEntry.host
    newEntry.index = existingEntry.index
    newEntry.query = QueryObject()
    newEntry.query?.values.append(QueryFilterObject(string: "test query"))
    
    dataManager.refresh()
    
    let result = dataManager.checkIfEntryExists(newEntry: newEntry)
    
    XCTAssertNotNil(result)
    
    let outcome = dataManager.areEntriesMatching(currentItem: existingEntry,
                                                 newEntry: newEntry)
    
    XCTAssertTrue(outcome)
  }
  
  @MainActor
  func testCheckIfEntryExistsWithDifferentDateField() throws {
    let existingEntry = RealmSearchEvent()
    existingEntry.host = UUID()
    existingEntry.index = "test-index"
    existingEntry.dateField = RealmSquashedFieldsArray()
    existingEntry.dateField?.squashedString = "test-date-field"
    
    dataManager.addNew(item: existingEntry)
    
    let newEntry = RealmSearchEvent()
    newEntry.host = existingEntry.host
    newEntry.index = existingEntry.index
    newEntry.dateField = RealmSquashedFieldsArray()
    newEntry.dateField?.squashedString = "different-date-field"
    
    dataManager.refresh()
    
    let result = dataManager.checkIfEntryExists(newEntry: newEntry)
    
    XCTAssertNil(result)
    
    let outcome = dataManager.areEntriesMatching(currentItem: existingEntry,
                                                 newEntry: newEntry)
    
    XCTAssertFalse(outcome)
  }
  
  @MainActor
  func testCheckIfEntryExistsWithDifferentRelativeRange() throws {
    let existingEntry = RealmSearchEvent()
    existingEntry.host = UUID()
    existingEntry.index = "test-index"
    existingEntry.relativeRange = RealmRelativeRangeFilter()
    existingEntry.relativeRange?.period = .Days
    existingEntry.relativeRange?.value = 7
    
    dataManager.addNew(item: existingEntry)
    
    let newEntry = RealmSearchEvent()
    newEntry.host = existingEntry.host
    newEntry.index = existingEntry.index
    newEntry.relativeRange = RealmRelativeRangeFilter()
    newEntry.relativeRange?.period = .Hours
    newEntry.relativeRange?.value = 24
    
    dataManager.refresh()
    
    let result = dataManager.checkIfEntryExists(newEntry: newEntry)
    
    XCTAssertNil(result)
    
    let outcome = dataManager.areEntriesMatching(currentItem: existingEntry,
                                                 newEntry: newEntry)
    
    XCTAssertFalse(outcome)
  }
  
  let referenceDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
  
  // Helper function to create dates relative to the reference date
  func date(offsetDays: Int) -> Date {
    return Calendar.current.date(byAdding: .day, value: offsetDays, to: referenceDate)!
  }
  
  @MainActor
  func testCheckIfEntryExistsWithSameAbsoluteRange() throws {
    let existingEntry = RealmSearchEvent()
    existingEntry.host = UUID()
    existingEntry.index = "test-index"
    existingEntry.absoluteRange = RealmAbsoluteDateRangeObject()
    existingEntry.absoluteRange?.to = date(offsetDays: 0) // 2021-01-01
    existingEntry.absoluteRange?.from = date(offsetDays: 0) // 2021-01-01
    
    dataManager.addNew(item: existingEntry)
    
    let newEntry = RealmSearchEvent()
    newEntry.host = existingEntry.host
    newEntry.index = existingEntry.index
    newEntry.absoluteRange = RealmAbsoluteDateRangeObject()
    newEntry.absoluteRange?.to = date(offsetDays: 0) // 2021-01-01
    newEntry.absoluteRange?.from = date(offsetDays: 0) // 2021-01-01
    
    dataManager.refresh()
    
    let result = dataManager.checkIfEntryExists(newEntry: newEntry)
    
    XCTAssertNotNil(result)
    
    let outcome = dataManager.areEntriesMatching(currentItem: existingEntry,
                                                 newEntry: newEntry)
    XCTAssertTrue(outcome)
  }
  
  @MainActor
  func testCheckIfEntryExistsWithDifferentAbsoluteRange() throws {
    let existingEntry = RealmSearchEvent()
    existingEntry.host = UUID()
    existingEntry.index = "test-index"
    existingEntry.absoluteRange = RealmAbsoluteDateRangeObject()
    existingEntry.absoluteRange?.from = date(offsetDays: 0) // 2021-01-01
    existingEntry.absoluteRange?.to = date(offsetDays: 1) // 2021-01-01
    
    dataManager.addNew(item: existingEntry)
    
    let newEntry = RealmSearchEvent()
    newEntry.host = existingEntry.host
    newEntry.index = existingEntry.index
    newEntry.absoluteRange = RealmAbsoluteDateRangeObject()
    newEntry.absoluteRange?.from = date(offsetDays: 0) // 2021-01-01
    newEntry.absoluteRange?.to = date(offsetDays: 2) // 2021-01-01
    
    dataManager.refresh()
    
    let result = dataManager.checkIfEntryExists(newEntry: newEntry)
    
    XCTAssertNil(result)
    
    let outcome = dataManager.areEntriesMatching(currentItem: existingEntry,
                                                 newEntry: newEntry)
    
    XCTAssertFalse(outcome)
  }
  
  @MainActor
  func testCheckIfEntryExistsWithMultipleEntries() {
    
    // Create and add multiple entries
    let host1 = UUID()
    let host2 = UUID()
    
    let entry1 = createFullSearchEvent(host: host1, index: "index1", query: "query1", dateField: "date1")
    let entry2 = createFullSearchEvent(host: host1, index: "index2", query: "query2", relativeRange: (.Days, 7))
    let entry3 = createFullSearchEvent(host: host2, index: "index1", query: "query3", absoluteRange: (date(offsetDays: 0), date(offsetDays: 7)))
    let entry4 = createFullSearchEvent(host: host2, index: "index2", query: "query4")
    
    [entry1, entry2, entry3, entry4].forEach { dataManager.addNew(item: $0) }
    
    dataManager.refresh()
    
    // Test 1: Exact match
    let matchingEntry1 = createFullSearchEvent(host: host1, index: "index1", query: "query1", dateField: "date1")
    XCTAssertNotNil(dataManager.checkIfEntryExists(newEntry: matchingEntry1))
    
    // Test 2: Different query
    let nonMatchingEntry1 = createFullSearchEvent(host: host1, index: "index1", query: "different query", dateField: "date1")
    XCTAssertNil(dataManager.checkIfEntryExists(newEntry: nonMatchingEntry1))
    
    // Test 3: Matching relative range
    let matchingEntry2 = createFullSearchEvent(host: host1, index: "index2", query: "query2", relativeRange: (.Days, 7))
    XCTAssertNotNil(dataManager.checkIfEntryExists(newEntry: matchingEntry2))
    
    // Test 4: Different relative range
    let nonMatchingEntry2 = createFullSearchEvent(host: host1, index: "index2", query: "query2", relativeRange: (.Hours, 24))
    XCTAssertNil(dataManager.checkIfEntryExists(newEntry: nonMatchingEntry2))
    
    // Test 5: Matching absolute range
    let matchingEntry3 = createFullSearchEvent(host: host2, index: "index1", query: "query3", absoluteRange: (date(offsetDays: 0), date(offsetDays: 7)))
    XCTAssertNotNil(dataManager.checkIfEntryExists(newEntry: matchingEntry3))
    
    // Test 6: Different absolute range
    let nonMatchingEntry3 = createFullSearchEvent(host: host2, index: "index1", query: "query3", absoluteRange: (date(offsetDays: 1), date(offsetDays: 8)))
    XCTAssertNil(dataManager.checkIfEntryExists(newEntry: nonMatchingEntry3))
    
    // Test 7: Different host
    let nonMatchingEntry4 = createFullSearchEvent(host: UUID(), index: "index2", query: "query4")
    XCTAssertNil(dataManager.checkIfEntryExists(newEntry: nonMatchingEntry4))
    
    // Test 8: Different index
    let nonMatchingEntry5 = createFullSearchEvent(host: host2, index: "index3", query: "query4")
    XCTAssertNil(dataManager.checkIfEntryExists(newEntry: nonMatchingEntry5))
  }
}
