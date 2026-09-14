// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON
import RealmSwift

@testable import Search_Ops

class FieldsQueryElasticTests: XCTestCase {
  
  var fields: Fields!
  var mockHostDetails: HostDetails!
  
  override func setUp() {
    super.setUp()
    fields = Fields()
    mockHostDetails = HostDetails()
    Request.mockedSession = MockURLSession(response: "{}")
  }
  
  override func tearDown() {
    Request.mockedSession = nil
    fields = nil
    mockHostDetails = nil
    super.tearDown()
  }
  
  func testQueryElasticWithEmptyFilter() async {
    let emptyFilter = FilterObject()
    let response = await Fields.QueryElastic(filterObject: emptyFilter, item: mockHostDetails, selectedIndex: "testIndex")
    
    XCTAssertNil(response.error)
    XCTAssertNotNil(response.jsonReq)
    // Add more assertions based on expected behavior for empty filter
  }
  
  func testQueryElasticWithDateField() async {
    let filter = FilterObject()
    filter.dateField = SquashedFieldsArray()
    filter.dateField?.fieldParts = ["timestamp"]
    filter.dateField?.squashedString = "timestamp"
    filter.dateField?.type = "date"
    
    // Requires either a relative range or absolute value
    filter.relativeRange = RelativeRangeFilter(period: .Days, value: 1)
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "testIndex")
    
    XCTAssertNil(response.error)
    XCTAssertTrue(response.jsonReq?.contains("timestamp") ?? false)
  }
  
  func testQueryElasticWithRelativeRange() async {
    let filter = FilterObject()
    filter.dateField = SquashedFieldsArray(squashedString: "timestamp")
    filter.relativeRange = RelativeRangeFilter(period: .Minutes, value: 5)
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "testIndex")
    
    XCTAssertNil(response.error)
    XCTAssertTrue(response.jsonReq?.contains("gte") ?? false)
    XCTAssertTrue(response.jsonReq?.contains("lte") ?? false)
  }
  
  func testQueryElasticWithAbsoluteRange() async {
    let filter = FilterObject()
    filter.dateField = SquashedFieldsArray(squashedString: "timestamp")
    filter.absoluteRange = AbsoluteDateRangeObject(from: Date(), to: Date().addingTimeInterval(3600))
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "testIndex")
    
    XCTAssertNil(response.error)
    XCTAssertTrue(response.jsonReq?.contains("gte") ?? false)
    XCTAssertTrue(response.jsonReq?.contains("lte") ?? false)
  }
  
  func testQueryElasticWithQueryObject() async {
    let filter = FilterObject()
    filter.query = QueryObject()
    filter.query?.values = List<QueryFilterObject>()
    filter.query?.values.append(QueryFilterObject(string: "test query"))
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "testIndex")
    
    XCTAssertNil(response.error)
    XCTAssertTrue(response.jsonReq?.contains("test query") ?? false)
  }
  
  func testQueryElasticWithSortObject() async {
    let filter = FilterObject()
    filter.sort = SortObject(order: .Ascending, field: SquashedFieldsArray(squashedString: "timestamp"))
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "testIndex")
    
    XCTAssertNil(response.error)
    XCTAssertTrue(response.jsonReq?.contains("\"sort\":{\"timestamp\":\"asc\"}") ?? false)
  }
  
  func testQueryElasticWithInvalidHostDetails() async {
    let filter = FilterObject()
    
    let response = await Fields.QueryElastic(filterObject: filter, item: nil, selectedIndex: "testIndex")
    
    XCTAssertNotNil(response.error)
    XCTAssertEqual(response.error?.title, "Request Error")
  }
  
  func testQueryElasticWithPagination() async {
    let filter = FilterObject()
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "testIndex", from: 10)
    
    XCTAssertNil(response.error)
    XCTAssertTrue(response.jsonReq?.contains("\"from\":10") ?? false)
  }
  
  func testResetIndexSpecificFiltersClearsDateAndSort() {
    let filter = FilterObject()
    filter.dateField = SquashedFieldsArray(squashedString: "Timestamp")
    filter.sort = SortObject(order: .Descending, field: SquashedFieldsArray(squashedString: "Timestamp"))
    filter.relativeRange = RelativeRangeFilter(period: .Hours, value: 1)
    filter.absoluteRange = AbsoluteDateRangeObject(from: Date(), to: Date())
    filter.query = QueryObject()
    filter.query?.values.append(QueryFilterObject(string: "status:200"))
    
    filter.resetIndexSpecificFilters()
    
    XCTAssertNil(filter.dateField)
    XCTAssertNil(filter.sort)
    XCTAssertNil(filter.relativeRange)
    XCTAssertNil(filter.absoluteRange)
    XCTAssertNotNil(filter.query)
    XCTAssertEqual(filter.query?.values.first?.string, "status:200")
  }
  
  func testQueryElasticAfterIndexResetContainsNoSortClause() async {
    let filter = FilterObject()
    filter.dateField = SquashedFieldsArray(squashedString: "Timestamp")
    filter.sort = SortObject(order: .Descending, field: SquashedFieldsArray(squashedString: "Timestamp"))
    filter.relativeRange = RelativeRangeFilter(period: .Hours, value: 1)
    
    // Simulate index switch resetting index-specific filters
    filter.resetIndexSpecificFilters()
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "differentIndex")
    
    XCTAssertNil(response.error)
    XCTAssertNotNil(response.jsonReq)
    XCTAssertFalse(response.jsonReq?.contains("\"sort\"") ?? true, "Payload should not contain sort clause after index reset")
    XCTAssertFalse(response.jsonReq?.contains("Timestamp") ?? true, "Payload should not contain previous index date field")
  }
  
  func testQueryElasticWithEmptySortFieldIgnored() async {
    let filter = FilterObject()
    filter.sort = SortObject(order: .Descending, field: SquashedFieldsArray(squashedString: "   "))
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "testIndex")
    
    XCTAssertNil(response.error)
    XCTAssertNotNil(response.jsonReq)
    XCTAssertFalse(response.jsonReq?.contains("\"sort\"") ?? true, "Payload should not contain sort clause when sort field is empty or whitespace")
  }
  
  func testQueryElasticPreservesQueryTextAfterIndexReset() async {
    let filter = FilterObject()
    filter.dateField = SquashedFieldsArray(squashedString: "Timestamp")
    filter.sort = SortObject(order: .Descending, field: SquashedFieldsArray(squashedString: "Timestamp"))
    filter.relativeRange = RelativeRangeFilter(period: .Hours, value: 2)
    filter.query = QueryObject()
    filter.query?.values.append(QueryFilterObject(string: "service:backend"))
    
    // User switches index -> index-specific filters cleared, query string kept
    filter.resetIndexSpecificFilters()
    
    let response = await Fields.QueryElastic(filterObject: filter, item: mockHostDetails, selectedIndex: "otherIndex")
    
    XCTAssertNil(response.error)
    XCTAssertNotNil(response.jsonReq)
    XCTAssertTrue(response.jsonReq?.contains("service:backend") ?? false, "Preserved query string should be present in payload")
    XCTAssertFalse(response.jsonReq?.contains("\"sort\"") ?? true, "Sort clause should be absent")
    XCTAssertFalse(response.jsonReq?.contains("Timestamp") ?? true, "Stale date field should be absent")
    XCTAssertFalse(response.jsonReq?.contains("\"range\"") ?? true, "Range filter should be absent")
  }
  
  func testFilterObjectClearVersusResetIndexSpecificFilters() {
    let filter1 = FilterObject()
    filter1.dateField = SquashedFieldsArray(squashedString: "Timestamp")
    filter1.sort = SortObject(order: .Descending, field: SquashedFieldsArray(squashedString: "Timestamp"))
    filter1.relativeRange = RelativeRangeFilter(period: .Hours, value: 1)
    filter1.query = QueryObject()
    filter1.query?.values.append(QueryFilterObject(string: "log_level:error"))
    
    filter1.resetIndexSpecificFilters()
    XCTAssertNil(filter1.dateField)
    XCTAssertNil(filter1.sort)
    XCTAssertNil(filter1.relativeRange)
    XCTAssertNotNil(filter1.query, "resetIndexSpecificFilters must preserve query")
    
    let filter2 = FilterObject()
    filter2.dateField = SquashedFieldsArray(squashedString: "Timestamp")
    filter2.sort = SortObject(order: .Descending, field: SquashedFieldsArray(squashedString: "Timestamp"))
    filter2.relativeRange = RelativeRangeFilter(period: .Hours, value: 1)
    filter2.query = QueryObject()
    filter2.query?.values.append(QueryFilterObject(string: "log_level:error"))
    
    filter2.clear()
    XCTAssertNil(filter2.dateField)
    XCTAssertNil(filter2.sort)
    XCTAssertNil(filter2.relativeRange)
    XCTAssertNil(filter2.query, "clear must reset everything including query")
  }
}
