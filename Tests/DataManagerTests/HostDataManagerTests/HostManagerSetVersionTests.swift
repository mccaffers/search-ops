// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

class HostManagerSetVersionTests: XCTestCase {
  
  var hostsDataManager: HostsDataManager!
  var hostDetail: HostDetails!
  
  @MainActor 
  override func setUp() {
    super.setUp()
    
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    RealmManager().clearRealmInstance()
    _ = RealmManager().getRealm(inMemory: true)
    
    // Initialize the HostsDataManager
    hostsDataManager = HostsDataManager()
    
    // Create a HostDetails object to use in tests
    hostDetail = HostDetails()
    hostDetail.id = UUID()
    hostDetail.version = "1.0"
  }
  
  override func tearDown() {
    hostsDataManager = nil
    hostDetail = nil
    super.tearDown()
  }
  
  @MainActor
  func testSetVersion() {
    // Given: A known initial version
    XCTAssertEqual(hostDetail.version, "1.0", "Initial version should be '1.0'")
    
    // When: setVersion is called with a new version
    HostsDataManager.setVersion(item: hostDetail, version: "2.0")
    
    // Then: The version of the host details should be updated
    XCTAssertEqual(hostDetail.version, "2.0", "The version should be updated to '2.0'")
  }
}
