// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

class HostManagerConnectionTests: XCTestCase {
  
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
    
    // Set up a HostDetails object to use in tests
    hostDetail = HostDetails()
    hostDetail.id = UUID()
    let hostObj = HostURL()
    hostObj.url = "https://example.com"
    hostObj.port = "8080"
    hostDetail.host = hostObj
    hostDetail.cloudid = "original-cloud-id"
  }
  
  override func tearDown() {
    hostsDataManager = nil
    hostDetail = nil
    super.tearDown()
  }
  
  @MainActor
  func testSetConnectionTypeToCloudID() {
    // Given: A host detail with initial URL connection type
    hostDetail.connectionType = .URL
    
    // When: Connection type is set to CloudID
    HostsDataManager.setConncetionType(item: hostDetail, connection: ConnectionType.CloudID)
    
    // Then: The host URL and port should be cleared
    XCTAssertTrue(hostDetail.host?.url.isEmpty ?? false, "URL should be cleared when connection type is CloudID")
    XCTAssertTrue(hostDetail.host?.port.isEmpty ?? false, "Port should be cleared when connection type is CloudID")
    XCTAssertEqual(hostDetail.connectionType, .CloudID, "The connection type should be updated to CloudID")
  }
  
  @MainActor 
  func testSetConnectionTypeToURL() {
    // Given: A host detail with initial CloudID connection type
    hostDetail.connectionType = .CloudID
    
    // When: Connection type is set to URL
    HostsDataManager.setConncetionType(item: hostDetail, connection: ConnectionType.URL)
    
    // Then: The cloudid should be cleared
    XCTAssertTrue(hostDetail.cloudid.isEmpty, "CloudID should be cleared when connection type is URL")
    XCTAssertEqual(hostDetail.connectionType, .URL, "The connection type should be updated to URL")
  }
}
