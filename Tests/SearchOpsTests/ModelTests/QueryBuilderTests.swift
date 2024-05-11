// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

class GenericQueryBuilderTests: XCTestCase {
  // Test for basic query construction
  func testBasicQueryConstruction() {
    let builder = GenericQueryBuilder()
    let result = builder.Create(queries: ["name:john"], compound: "must", dateField: nil, range: nil)
    
    XCTAssertEqual(result.query?.bool?.must?.count, 1)
    XCTAssertEqual(result.query?.bool?.must?.first?.query_string?.query, "name:john")
  }
  
  // Test for compound query handling
  func testCompoundQueryHandling() {
    let builder = GenericQueryBuilder()
    let result = builder.Create(queries: ["name:john", "city:new york"], compound: "should", dateField: nil, range: nil)
    
    XCTAssertEqual(result.query?.bool?.must?.first?.bool?.should?.count, 2)
    XCTAssertEqual(result.query?.bool?.must?.first?.bool?.should?.first?.query_string?.query, "name:john")
    XCTAssertEqual(result.query?.bool?.must?.first?.bool?.should?.last?.query_string?.query, "city:new york")
  }
  
  // Test for date range functionality
  func testDateRangeQuery() {
    let builder = GenericQueryBuilder()
    let dateRange = GenericQueryBuilder.Date(lte: "2021-12-31", gte: "2021-01-01")
    let result = builder.Create(queries: ["name:john"], compound: "must", dateField: "createdAt", range: dateRange)
    
    XCTAssertEqual(result.query?.bool?.must?.last?.range?["createdAt"]?.gte, "2021-01-01")
    XCTAssertEqual(result.query?.bool?.must?.last?.range?["createdAt"]?.lte, "2021-12-31")
  }
  
  // Test for sorting functionality
  func testSortingQuery() {
    let builder = GenericQueryBuilder()
    let result = builder.Create(queries: ["name:john"], compound: "must", dateField: nil, range: nil, sortBy: ["name": "desc"])
    
    XCTAssertEqual(result.sort?["name"], "desc")
  }
  
  // Test for a complex query combining multiple features
  func testComplexQuery() {
    let builder = GenericQueryBuilder()
    let dateRange = GenericQueryBuilder.Date(lte: "2021-12-31", gte: "2021-01-01")
    let result = builder.Create(queries: ["name:john", "city:new york"], compound: "should", dateField: "createdAt", range: dateRange, sortBy: ["name": "desc"])
    
    XCTAssertEqual(result.sort?["name"], "desc")
    XCTAssertEqual(result.query?.bool?.must?.first?.bool?.should?.count, 2)
    XCTAssertEqual(result.query?.bool?.must?.last?.range?["createdAt"]?.gte, "2021-01-01")
  }
  
  
  
  func testEject() {
    // Given
    let queryObject = QueryObject()
    let queryFilterObject1 = QueryFilterObject(string: "Filter 1")
    let queryFilterObject2 = QueryFilterObject(string: "Filter 2")
    queryObject.values.append(queryFilterObject1)
    queryObject.values.append(queryFilterObject2)
    queryObject.compound = .must
    
    // When
    let ejectedObject = queryObject.eject()
    
    // Then
    XCTAssertEqual(ejectedObject.values.count, 2)
    XCTAssertEqual(ejectedObject.compound, .must)
    
    // Verify that the detached objects are copies, not references
    for index in 0..<queryObject.values.count {
      XCTAssertNotIdentical(queryObject.values[index], ejectedObject.values[index])
      XCTAssertEqual(queryObject.values[index].string, ejectedObject.values[index].string)
    }
  }
  
}
