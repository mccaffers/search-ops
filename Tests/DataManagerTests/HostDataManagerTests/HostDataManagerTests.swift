// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift

@testable import Search_Ops

final class HostsDataManagerTests: XCTestCase {
  
  var hostsDataManager: HostsDataManager!
  var testHostDetail: HostDetails!
  var realm: Realm!
  
  @MainActor
  override func setUp() {
    super.setUp()
    
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    RealmManager().clearRealmInstance()
    realm = RealmManager().getRealm(inMemory: true)
    
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
    try! realm.write {
        realm.deleteAll()
    }
    realm = nil
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
  
  @MainActor
  func testRemoveTrailingSlash_WithTrailingSlash() {
    // Arrange
    let host = HostDetails()
    host.host = HostURL()
    host.host?.url = "https://example.com/"
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.removeTrailingSlash(item: host)
    
    // Assert
    XCTAssertEqual(host.host?.url, "https://example.com", "Trailing slash should be removed")
  }
  
  @MainActor
  func testRemoveTrailingSlash_WithoutTrailingSlash() {
    // Arrange
    let host = HostDetails()
    host.host = HostURL()
    host.host?.url = "https://example.com"
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.removeTrailingSlash(item: host)
    
    // Assert
    XCTAssertEqual(host.host?.url, "https://example.com", "URL should remain unchanged")
  }
  
  @MainActor
  func testRemoveTrailingSlash_WithEmptyURL() {
    // Arrange
    let host = HostDetails()
    host.host = HostURL()
    host.host?.url = ""
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.removeTrailingSlash(item: host)
    
    // Assert
    XCTAssertEqual(host.host?.url, "", "Empty URL should remain unchanged")
  }
  
  @MainActor
  func testRemoveTrailingSlash_WithMultipleTrailingSlashes() {
    // Arrange
    let host = HostDetails()
    host.host = HostURL()
    host.host?.url = "https://example.com///"
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.removeTrailingSlash(item: host)
    
    // Assert
    XCTAssertEqual(host.host?.url, "https://example.com//", "Only one trailing slash should be removed")
  }
  
  @MainActor
  func testUpdateAuthentication_ToAPIKey() {
    // Arrange
    let host = HostDetails()
    host.username = "testuser"
    host.password = "testpass"
    host.authToken = "testtoken"
    host.apiToken = "testapitoken"
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.updateAuthentication(item: host, selection: .APIKey)
    
    // Assert
    XCTAssertEqual(host.authenticationType, .APIKey)
    XCTAssertEqual(host.username, "")
    XCTAssertEqual(host.password, "")
    XCTAssertEqual(host.authToken, "")
    XCTAssertEqual(host.apiToken, "")
  }
  
  @MainActor
  func testUpdateAuthentication_ToAuthToken() {
    // Arrange
    let host = HostDetails()
    host.username = "testuser"
    host.password = "testpass"
    host.apiKey = "testapikey"
    host.apiToken = "testapitoken"
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.updateAuthentication(item: host, selection: .AuthToken)
    
    // Assert
    XCTAssertEqual(host.authenticationType, .AuthToken)
    XCTAssertEqual(host.username, "")
    XCTAssertEqual(host.password, "")
    XCTAssertEqual(host.apiKey, "")
    XCTAssertEqual(host.apiToken, "")
  }
  
  @MainActor
  func testUpdateAuthentication_ToUsernamePassword() {
    // Arrange
    let host = HostDetails()
    host.authToken = "testtoken"
    host.apiKey = "testapikey"
    host.apiToken = "testapitoken"
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.updateAuthentication(item: host, selection: .UsernamePassword)
    
    // Assert
    XCTAssertEqual(host.authenticationType, .UsernamePassword)
    XCTAssertEqual(host.authToken, "")
    XCTAssertEqual(host.apiKey, "")
    XCTAssertEqual(host.apiToken, "")
  }
  
  @MainActor
  func testUpdateAuthentication_ToAPIToken() {
    // Arrange
    let host = HostDetails()
    host.username = "testuser"
    host.password = "testpass"
    host.authToken = "testtoken"
    host.apiKey = "testapikey"
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.updateAuthentication(item: host, selection: .APIToken)
    
    // Assert
    XCTAssertEqual(host.authenticationType, .APIToken)
    XCTAssertEqual(host.username, "")
    XCTAssertEqual(host.password, "")
    XCTAssertEqual(host.authToken, "")
    XCTAssertEqual(host.apiKey, "")
  }
  
  @MainActor
  func testUpdateAuthentication_ToNone() {
    // Arrange
    let host = HostDetails()
    host.username = "testuser"
    host.password = "testpass"
    host.authToken = "testtoken"
    host.apiKey = "testapikey"
    host.apiToken = "testapitoken"
    
    try! realm.write {
      realm.add(host)
    }
    
    // Act
    HostsDataManager.updateAuthentication(item: host, selection: .None)
    
    // Assert
    XCTAssertEqual(host.authenticationType, .None)
    // Note: The current implementation doesn't clear fields when set to None
    // If this is desired behavior, you might want to update the implementation
    // and then update this test accordingly
  }
}
