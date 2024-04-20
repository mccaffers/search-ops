// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class HostManagerCheckHostTests: XCTestCase {
  
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
    
    // Add these hosts to the DataManager's items
//    hostsDataManager.items = [host1, host2]
    hostsDataManager.addNew(item: host1)
    hostsDataManager.addNew(item: host2)
    
    // Keep a reference to the sample data
    sampleHosts.append(contentsOf: [host1, host2])
  }
  
  override func tearDown() {
    hostsDataManager = nil
    sampleHosts.removeAll()
    super.tearDown()
  }
  
  @MainActor
  func testGetHostByID_ValidID() {
    // Given: Valid UUID of a known host
    let validID = sampleHosts.first!.id
    
    // When: getHostByID is called with a valid ID
    let host = hostsDataManager.getHostByID(validID)
    
    // Then: The method should return the correct HostDetails object
    XCTAssertNotNil(host, "Host should not be nil")
    XCTAssertEqual(host?.id, validID, "The retrieved host ID should match the requested ID")
    XCTAssertEqual(host?.name, "Server A", "The retrieved host name should be 'Server A'")
  }
  
  @MainActor
  func testGetHostByID_InvalidID() {
    // Given: Invalid UUID
    let invalidID = UUID()
    
    // When: getHostByID is called with an invalid ID
    let host = hostsDataManager.getHostByID(invalidID)
    
    // Then: The method should return nil
    XCTAssertNil(host, "Host should be nil for an invalid ID")
  }
}
