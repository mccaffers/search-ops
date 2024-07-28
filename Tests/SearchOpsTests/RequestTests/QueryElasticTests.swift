// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON
import RealmSwift

@testable import SearchOps
class FieldsQueryElasticTests: XCTestCase {
  
  var fields: Fields!
  var mockHostDetails: HostDetails!
  
  override func setUp() {
    super.setUp()
    fields = Fields()
    mockHostDetails = HostDetails()
    // Setup mock host details as needed
  }
  
  override func tearDown() {
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
}
