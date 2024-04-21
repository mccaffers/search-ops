// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift

@testable import SearchOps

final class SearchRenderTests: XCTestCase  {
  
  var searchRender: SearchRender!
  var filterObject: FilterObject!
  var queryObject: QueryObject!
  var squasedFieldsArray: SquasedFieldsArray!
  var relativeRangeFilter: RelativeRangeFilter!
  var sortObject: SortObject!
  var hostDetails: HostDetails!
  var limitObj: LimitObj!
  
  override func setUp() {
    super.setUp()
    
    // Initialize dependencies
    queryObject = QueryObject()
    queryObject.compound = .must  // or .should, as per test case needs
    queryObject.values.append(objectsIn: [
      QueryFilterObject(string: "filter1"),
      QueryFilterObject(string: "filter2")
    ])
    
    squasedFieldsArray = SquasedFieldsArray(squashedString: "exampleField")
    squasedFieldsArray.fieldParts = ["part1", "part2"]
    squasedFieldsArray.type = "text"
    squasedFieldsArray.index = "mainIndex"
    squasedFieldsArray.visible = true
    
    relativeRangeFilter = RelativeRangeFilter(period: .Hours, value: 2.0) // Set to 2 hours for testing
    
    // Initialize SortObject with the squasedFieldsArray
    sortObject = SortObject(order: SortOrderEnum.Ascending, field: squasedFieldsArray)
    
    // Initialize FilterObject with all properties including the SortObject
    filterObject = FilterObject(
      query: queryObject,
      dateField: squasedFieldsArray,
      relativeRange: relativeRangeFilter,
      absoluteRange: nil,  // Adjust with actual parameters
      sort: sortObject  // Use the initialized SortObject
    )
    
    hostDetails = HostDetails()
    hostDetails.host = HostURL()
    hostDetails.host?.url = "example.com"
    hostDetails.host?.port = "8080"
    limitObj = LimitObj(size: 10)
    
    // Initialize the class to be tested
    searchRender = SearchRender()
  }
  
  func testCallWithValidInput() async throws {
    // Arrange
    var result: RenderResult?
    
    // Act
    result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    // Assert
    XCTAssertNotNil(result, "Result should not be nil")
    // Add more specific assertions here based on the properties of RenderResult
  }
  
  func testSortObjectProperties() {
    // Test the properties of SortObject
    XCTAssertEqual(sortObject.order, .Ascending)
    XCTAssertEqual(sortObject.field, squasedFieldsArray, "Sort field should match the initialized SquasedFieldsArray")
  }
  
  override func tearDown() {
    searchRender = nil
    super.tearDown()
  }
}
