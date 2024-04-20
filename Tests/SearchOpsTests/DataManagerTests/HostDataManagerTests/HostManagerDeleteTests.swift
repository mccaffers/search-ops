// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

class HostManagerDeleteTests: XCTestCase {
  
  var hostsDataManager: HostsDataManager!
  var sampleHosts: [HostDetails] = []
  
  @MainActor
  override func setUp() {
    super.setUp()
    
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    RealmManager().clearRealmInstance()
    _ = RealmManager().getRealm(inMemory: true)
    
    // Initialize the HostsDataManager
    hostsDataManager = HostsDataManager()
    
    // Create sample host details to use in the test
    let host1 = HostDetails()
    host1.id = UUID()
    host1.name = "Server A"
    
    let host2 = HostDetails()
    host2.id = UUID()
    host2.name = "Server B"
    
    let host3 = HostDetails()
    host3.id = UUID()
    host3.name = "Server C"
    
    // Populate hostsDataManager with sample data
    hostsDataManager.addNew(item: host1)
    hostsDataManager.addNew(item: host2)
    hostsDataManager.addNew(item: host3)
    
    // Keep a reference to the sample data
    sampleHosts.append(contentsOf: [host1, host2, host3])
  }
  
  override func tearDown() {
    hostsDataManager = nil
    sampleHosts.removeAll()
    super.tearDown()
  }
  
  @MainActor
  func testDeleteItems() async {
    // Given: Three hosts in the manager
    XCTAssertEqual(hostsDataManager.items.count, 3, "Should start with 3 hosts")
    
    // When: Deleting two hosts
    let hostsToDelete = [sampleHosts[0], sampleHosts[2]] // Delete first and third hosts
    await hostsDataManager.deleteItems(itemsForDeletion: hostsToDelete)
    
    // Then: Only one host should remain
    XCTAssertEqual(hostsDataManager.items.count, 1, "Should be 1 host remaining after deletion")
    XCTAssertEqual(hostsDataManager.items.first?.id, sampleHosts[1].id, "The remaining host should be 'Server B'")
  }
}
