// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

class HostDataManagerUpdateTests: XCTestCase {
  
  var hostsDataManager: HostsDataManager!
  var hostDetail: HostDetails!
  var headers: [LocalHeaders]!
  
  @MainActor
  override func setUp() {
    super.setUp()
    
    // Initialize the HostsDataManager
    hostsDataManager = HostsDataManager()
    
    // Create a HostDetails object to use in the test
    hostDetail = HostDetails()
    hostDetail.id = UUID()
    
    let myHeader = Headers()
    myHeader.id = UUID()
    myHeader.header = "Test-Header"
    myHeader.value = "Test-Value"
    
    let customHeaders : [Headers] = [myHeader]
    hostDetail.customHeaders.append(objectsIn: customHeaders) // Assuming Headers is a Realm Object
    
  }
  
  override func tearDown() {
    hostsDataManager = nil
    hostDetail = nil
    headers = nil
    super.tearDown()
  }
  
  @MainActor 
  func testUpdateList() {
    
    // Given: A host detail with initial headers
    XCTAssertEqual(hostDetail.customHeaders.count, 1)
    XCTAssertEqual(hostDetail.customHeaders.first?.header, "Test-Header")
    XCTAssertEqual(hostDetail.customHeaders.first?.value, "Test-Value")
    
    headers = [
      LocalHeaders(id: UUID(), header: "Test-Header", value: "Test-Value"),
      LocalHeaders(id: UUID(), header: "Test-Header", value: "Test-Value")
    ]
    
    // When: updateList is called with new headers
    hostsDataManager.updateList(item: hostDetail, customHeaders: headers)
    XCTAssertEqual(hostDetail.customHeaders.count, 2)
    // Then: the host details should have updated headers
    XCTAssertEqual(hostDetail.customHeaders.last?.header, "Test-Header", "The new header should be 'Test-Header'")
    XCTAssertEqual(hostDetail.customHeaders.last?.value, "Test-Value", "The new value should be 'Test-Value'")
  }
}
