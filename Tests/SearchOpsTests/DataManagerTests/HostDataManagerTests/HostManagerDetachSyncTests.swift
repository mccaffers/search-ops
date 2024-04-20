// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

class HostManagerDetachSyncTests: XCTestCase {
  
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
    hostDetail.detachedID = UUID()  // Ensure detachedID is different from the initial ID
  }
  
  override func tearDown() {
    hostsDataManager = nil
    hostDetail = nil
    super.tearDown()
  }
  
  @MainActor
  func testDetachFromSync() {
    // Given: A host detail with initial ID and a distinct detachedID
    let initialID = hostDetail.id
    let expectedDetachedID = hostDetail.detachedID
    
    XCTAssertNotEqual(initialID, expectedDetachedID, "Initial and detached IDs should be different for a valid test.")
    
    // When: detachFromSync is called
    HostsDataManager.detachFromSync(item: hostDetail)
    
    // Then: The ID of the host details should be updated to the detachedID
    XCTAssertEqual(hostDetail.id, expectedDetachedID, "The host ID should be updated to its detached ID.")
  }
}
