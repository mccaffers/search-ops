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

final class FilterHistoryManagerDuplicatesTests: XCTestCase {
  
  @MainActor
  override func setUp() {
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  
  @MainActor 
  func testRemoveQueryDuplicates() {
    
    let manager = FilterHistoryDataManager()
    
    // Create test data
    let query1 = QueryObject()
    query1.values.append(QueryFilterObject(string: "apple"))
    query1.values.append(QueryFilterObject(string: "banana"))
    query1.compound = .must
    
    let query2 = QueryObject()
    query2.values.append(QueryFilterObject(string: "banana"))
    query2.values.append(QueryFilterObject(string: "apple"))
    query2.compound = .must
    
    let query3 = QueryObject()
    query3.values.append(QueryFilterObject(string: "cherry"))
    query3.compound = .should
    
    let item1 = RealmFilterObject()
    item1.query = query1
    
    let item2 = RealmFilterObject()
    item2.query = query2
    
    let item3 = RealmFilterObject()
    item3.query = query3
    
    let item4 = RealmFilterObject()
    item4.query = nil
    
//    let items
    let items = [item1, item2, item3, item4, item1]  // Note: item1 is repeated
    
    for item in items {
      if let realm = RealmManager().getRealm() {
        try? realm.write {
          realm.add(item)
        }
      }
    }
    
    manager.refresh()
    
    // Call the function
    manager.removeQueryDuplicates()
    
    manager.refresh()
    
    // Assertions
    XCTAssertEqual(manager.items.count, 3, "Should have 3 unique items")
    
    // Check that item1/item2 (duplicates) are represented once
    XCTAssertEqual(manager.items.filter { $0.query?.compound == .must }.count, 1)
    
    // Check that item3 is present
    XCTAssertEqual(manager.items.filter { $0.query?.compound == .should }.count, 1)
    
    // Check that item4 (nil query) is present
    XCTAssertEqual(manager.items.filter { $0.query == nil }.count, 1)
    
    // Verify the content of the unique must compound query
    if let mustQuery = manager.items.first(where: { $0.query?.compound == .must })?.query {
      XCTAssertEqual(mustQuery.values.count, 2)
      let strings = mustQuery.values.map { $0.string }.sorted()
      XCTAssertEqual(strings, ["apple", "banana"])
    } else {
      XCTFail("Must compound query not found")
    }
  }
}
