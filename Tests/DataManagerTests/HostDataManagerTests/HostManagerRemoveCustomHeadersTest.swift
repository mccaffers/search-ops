// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

class HostManagerRemoveCustomHeadersTest: XCTestCase {
  
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
    
    let header1 = Headers()
    header1.id = UUID()
    header1.header = "Header1"
    header1.value = "Value1"
    header1.focusedIndexHeader = 0
    header1.focusedIndexValue = 0.5

    let header2 = Headers()
    header2.id = UUID()
    header2.header = "Header2"
    header2.value = "Value2"
    header2.focusedIndexHeader = 1
    header2.focusedIndexValue = 1.5
    
    let header3 = Headers()
    header3.id = UUID()
    header3.header = "Header3"
    header3.value = "Value3"
    header3.focusedIndexHeader = 2
    header3.focusedIndexValue = 2.5
    
    
    hostDetail = HostDetails()
    hostDetail.customHeaders.append(objectsIn: [
      header1,
      header2,
      header3
    ])
    
    hostsDataManager.addNew(item: hostDetail)
  
  }
  
  override func tearDown() {
    hostsDataManager = nil
    hostDetail = nil
    super.tearDown()
  }
  
  @MainActor 
  func testRemoveCustomHeaders() {
    // Given: A host detail with three custom headers
    XCTAssertEqual(hostDetail.customHeaders.count, 3, "There should initially be three headers")
    
    // Header to be removed
    let headerToRemoveID = hostDetail.customHeaders[1].id
    
    // When: removeCustomHeaders is called with the ID of the second header
    HostsDataManager.removeCustomHeaders(item: hostDetail, id: headerToRemoveID)
    
    // Then: The second header should be removed and the list should contain two headers
    XCTAssertEqual(hostDetail.customHeaders.count, 2, "There should be two headers after removal")
    XCTAssertNil(hostDetail.customHeaders.first(where: {$0.id == headerToRemoveID}), "The removed header should not be present in the list")
    
    // Check reindexing
    XCTAssertEqual(hostDetail.customHeaders[0].focusedIndexHeader, 0, "First header index should be 0")
    XCTAssertEqual(hostDetail.customHeaders[0].focusedIndexValue, 0.5, "First header value index should be 0.5")
    XCTAssertEqual(hostDetail.customHeaders[1].focusedIndexHeader, 1, "Second header index should be 1")
    XCTAssertEqual(hostDetail.customHeaders[1].focusedIndexValue, 1.5, "Second header value index should be 1.5")
  }
}
