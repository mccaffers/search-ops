// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift

@testable import SearchOps

class FilterHistoryDataManagerDeleteTests: XCTestCase {
  
  var manager: FilterHistoryDataManager!
  
  @MainActor
  override func setUp() {
    super.setUp()
    
    // Setup in-memory Realm for testing
    _ = RealmManager().getRealm(inMemory: true)
    
    manager = FilterHistoryDataManager()
    setupInitialData()
  }
  
  @MainActor
  func setupInitialData() {
    // Clear any existing items first
    manager.clear()

    // Add items with varying dates
    let item1 = RealmFilterObject()
    item1.date = Date.now
    manager.addNew(item: item1)
    
    let item2 = RealmFilterObject()
    item2.date = Date.now.addingTimeInterval(-3600) // 1 hour ago
    manager.addNew(item: item2)
    
    let item3 = RealmFilterObject()
    item3.date = Date.now.addingTimeInterval(-7200) // 2 hours ago
    manager.addNew(item: item3)
  }
  
  @MainActor
  func testDeleteAll() {
    manager.clear()
    XCTAssertTrue(manager.items.isEmpty, "All items should be deleted from the manager.")
  }
  
  override func tearDown() {
    manager = nil
    super.tearDown()
  }
}
