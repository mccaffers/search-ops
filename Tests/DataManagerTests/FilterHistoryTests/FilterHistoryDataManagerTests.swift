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

final class FilterHistoryDataManagerHighLevelTests: XCTestCase {
  
  @MainActor
  override func setUp() {
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  @MainActor
  func testInitialization() {
    RealmManager().clearRealmInstance()
    
    let manager = FilterHistoryDataManager()
    XCTAssertNotNil(manager.items, "Items should be initialized.")
  }
  
  @MainActor
  func testClear() {
    RealmManager().clearRealmInstance()
    
    let manager = FilterHistoryDataManager()
    let newItem = RealmFilterObject()
    manager.addNew(item: newItem)
    XCTAssertTrue(manager.items.contains(newItem), "New item should be added to items.")
    manager.clear()
    XCTAssertTrue(manager.items.isEmpty, "Items should be empty after clear.")
  }
  
}
