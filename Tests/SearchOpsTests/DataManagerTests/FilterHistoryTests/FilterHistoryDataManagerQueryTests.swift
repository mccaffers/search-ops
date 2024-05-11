// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift

@testable import SearchOps

class FilterHistoryDataManagerQueryTests: XCTestCase {
  
  var manager: FilterHistoryDataManager!
  
  @MainActor
  override func setUp() {
    super.setUp()
    
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    _ = RealmManager().getRealm(inMemory: true)
    
    manager = FilterHistoryDataManager()
    setupInitialData()
  }
  
  @MainActor
  func setupInitialData() {
    let item1 = RealmFilterObject()
    item1.query = createQueryObject(strings: ["test", "sample"], compound: .must)
    item1.relativeRange = RelativeRangeFilter(period: .Hours, value: 1.0).ejectRealmObject()
    
    let item2 = RealmFilterObject()
    item2.query = createQueryObject(strings: ["no match"], compound: .should)
    item2.relativeRange = RelativeRangeFilter(period: .Days, value: 1.0).ejectRealmObject()
    
    manager.addNew(item: item1)
    manager.addNew(item: item2)
  }
  
  func createQueryObject(strings: [String], compound: QueryCompoundEnum) -> QueryObject {
    let queryObject = QueryObject()
    for string in strings {
      queryObject.values.append(QueryFilterObject(string: string))
    }
    queryObject.compound = compound
    return queryObject
  }
  
  @MainActor
  func testCheckIfValueExistsWithQueryAndRelativeRange() {
    
    var myFilter = FilterObject()
    myFilter.relativeRange = RelativeRangeFilter(period: .Hours, value: 1.0)
    myFilter.query = QueryObject()

    let queryObject = QueryObject()
    let queryFilterObject1 = QueryFilterObject(string: "Filter 1")
    let queryFilterObject2 = QueryFilterObject(string: "Filter 2")
    myFilter.query?.values =  List<QueryFilterObject>()
    myFilter.query?.values.append(queryFilterObject1)
    myFilter.query?.values.append(queryFilterObject2)
    myFilter.query?.compound = .must
    
    SearchMainViewLogic.SaveFilter(filterObject: myFilter)
    
    manager.refresh()
    let resultId = manager.checkIfValueExists(query: myFilter.query?.values)
    
    XCTAssertNotNil(resultId, "Should return a UUID of an item that matches both the query and the relative range filter.")
  }
  
  @MainActor
  func testUpdateDateForFilterHistory() {
    
    let expectedDate = Date.now
    let expectedCount = 2 // assuming the item was updated once after initialization
    
    guard let item = manager.items.first else {
      XCTFail("There should be at least one item to test")
      return
    }
    
    manager.updateDateForFilterHistory(id: item.id)
    
    let updatedItem = manager.items.first(where: { $0.id == item.id })
    XCTAssertNotNil(updatedItem, "Updated item should exist.")
    
    let calendar = Calendar.current
    
    // Compare hours, as the time can be slightly off depending on how fast the tests run
    XCTAssertEqual(calendar.component(.hour, from: updatedItem!.date),
                   calendar.component(.hour, from: expectedDate),
                                      "Date should be updated to the current time.")
    XCTAssertEqual(updatedItem?.count, expectedCount, "Count should be incremented by 1.")
  }
  
  override func tearDown() {
    manager = nil
    super.tearDown()
  }
}
