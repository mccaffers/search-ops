// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift

@testable import SearchOps

final class HostsDataManagerTests: XCTestCase {
  
  var hostsDataManager: HostsDataManager!
  var testHostDetail: HostDetails!
  
  @MainActor
  override func setUp() {
    super.setUp()
    
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    RealmManager().clearRealmInstance()
    _ = RealmManager().getRealm(inMemory: true)
    
    // Initialize the HostsDataManager
    hostsDataManager = HostsDataManager()
    
    // Set up a HostDetails object to use in tests
    testHostDetail = HostDetails()
    testHostDetail.id = UUID()
    testHostDetail.name = "Test Server"
    
    let host = HostURL()
    host.url = "https://test.com"
    host.port = "8080"
    testHostDetail.host = host
    testHostDetail.version = "1.0"
  }
  
  override func tearDown() {
    // Clean up any objects and resources
    hostsDataManager = nil
    testHostDetail = nil
    super.tearDown()
  }
  
  @MainActor
  func testSaveItem() {
    // This test will verify if the item's 'draft' property is set to false when saveItem is called.
    
    // Initially setting draft to true
    testHostDetail.draft = true
    
    // Call saveItem to supposedly persist changes
    HostsDataManager.saveItem(item: testHostDetail)
    
    // Check if the item's draft status has changed to false
    XCTAssertFalse(testHostDetail.draft, "saveItem should set draft to false")
  }
}
