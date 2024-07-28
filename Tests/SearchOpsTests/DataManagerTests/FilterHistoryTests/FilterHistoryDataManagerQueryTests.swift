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
  var realm: Realm!
  
  @MainActor
  override func setUp() {
    super.setUp()
    
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    realm = RealmManager().getRealm(inMemory: true)
    
    manager = FilterHistoryDataManager()
    
  }
  
  override func tearDown() {
    manager = nil
    try! realm.write {
      realm.deleteAll()
    }
    realm = nil
    super.tearDown()
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
    setupInitialData()
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
    setupInitialData()
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
  
  @MainActor
  func testDeleteOldest_WithItemsMoreThan50_DeletesOldestItem() {
    // Arrange
    let oldestDate = Date.distantPast
    let newerDate = Date()
    
    try! realm.write {
      // Add exactly 51 items (50 + 1 to trigger deletion)
      for i in 0...50 {
        let item = RealmFilterObject()
        item.date = i == 0 ? oldestDate : newerDate
        realm.add(item)
      }
    }
    
    // Act
    manager.deleteOldest()
    
    // Assert
    XCTAssertEqual(realm.objects(RealmFilterObject.self).count, 50, "There should be 50 items after deletion")
    XCTAssertFalse(realm.objects(RealmFilterObject.self).contains { $0.date == oldestDate }, "The oldest item should have been deleted")
  }
  
  @MainActor
  func testUpdateServerList_AddsNewItem() {
    // Arrange
    let newItem = RealmFilterObject()
    newItem.id = UUID()
    newItem.date = Date()
    
    // Act
    manager.updateServerList(item: newItem)
    
    // Assert
    XCTAssertEqual(realm.objects(RealmFilterObject.self).count, 1, "One item should be added to the Realm")
    XCTAssertNotNil(realm.object(ofType: RealmFilterObject.self, forPrimaryKey: newItem.id), "The new item should be found in the Realm")
  }
  
  @MainActor
  func testUpdateServerList_UpdatesExistingItem() {
    // Arrange
    let existingItem = RealmFilterObject()
    existingItem.id = UUID()
    existingItem.date = Date.distantPast
    try! realm.write {
      realm.add(existingItem)
    }
    
    let updatedItem = RealmFilterObject()
    updatedItem.id = existingItem.id
    updatedItem.date = Date()
    
    // Act
    manager.updateServerList(item: updatedItem)
    
    // Assert
    XCTAssertEqual(realm.objects(RealmFilterObject.self).count, 1, "The item count should remain the same")
    let retrievedItem = realm.object(ofType: RealmFilterObject.self, forPrimaryKey: existingItem.id)
    XCTAssertNotNil(retrievedItem, "The item should still exist in the Realm")
    XCTAssertEqual(retrievedItem?.date, updatedItem.date, "The item's date should be updated")
  }
  
  @MainActor
  func testUpdateServerList_DeletesOldestWhenExceeding50Items() {
    // Arrange
    let oldestDate = Date.distantPast
    try! realm.write {
      for i in 0...49 {
        let item = RealmFilterObject()
        item.id = UUID()
        item.date = i == 0 ? oldestDate : Date()
        realm.add(item)
      }
    }
    
    let newItem = RealmFilterObject()
    newItem.id = UUID()
    newItem.date = Date()
    
    // Act
    manager.updateServerList(item: newItem)
    
    // Assert
    XCTAssertEqual(realm.objects(RealmFilterObject.self).count, 50, "There should still be 50 items after adding the 51st")
    XCTAssertNil(realm.objects(RealmFilterObject.self).first(where: { $0.date == oldestDate }), "The oldest item should have been deleted")
    XCTAssertNotNil(realm.object(ofType: RealmFilterObject.self, forPrimaryKey: newItem.id), "The new item should be in the Realm")
  }
  
}
