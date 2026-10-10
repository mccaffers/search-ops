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
    host.authenticationType = .UsernamePassword
    host.username = "testuser"
    host.password = "testpass"

    try! realm.write {
      realm.add(host)
    }

    // Act
    HostsDataManager.updateAuthentication(item: host, selection: .None)

    // Assert
    XCTAssertEqual(host.authenticationType, .None)
    XCTAssertEqual(host.username, "")
    XCTAssertEqual(host.password, "")
  }

  @MainActor
  func testUpdateAuthentication_ToNoneWhenAlreadyNoneKeepsLegacyCredentials() {
    // Arrange: hosts saved before auth types existed sit on None with credentials
    let host = HostDetails()
    host.username = "testuser"
    host.password = "testpass"
    host.apiKey = "testapikey"

    try! realm.write {
      realm.add(host)
    }

    // Act
    HostsDataManager.updateAuthentication(item: host, selection: .None)

    // Assert
    XCTAssertEqual(host.username, "testuser")
    XCTAssertEqual(host.password, "testpass")
    XCTAssertEqual(host.apiKey, "testapikey")
  }

  // Mirrors the macOS edit form: it edits a copy, tidies the connection fields and saves over the original
  @MainActor
  func testEditingACopyKeepsFieldsTheFormDoesNotShow() {
    // Arrange: a host on None with legacy credentials and a leftover Cloud ID
    let saved = testHostDetail!
    saved.connectionType = .URL
    saved.cloudid = "leftover:Y2xvdWQ="
    saved.username = "testuser"
    saved.password = "testpass"
    hostsDataManager.addNew(item: saved)
    let createdDate = saved.createdDate

    // Act
    let form = saved.generateCopy()
    form.name = "Renamed"
    form.id = saved.id
    HostsDataManager.setConncetionType(item: form, connection: form.connectionType)
    hostsDataManager.addNew(item: form)

    // Assert
    let stored = realm.object(ofType: HostDetails.self, forPrimaryKey: saved.id)
    XCTAssertEqual(stored?.name, "Renamed")
    XCTAssertEqual(stored?.authenticationType, AuthenticationTypes.None)
    XCTAssertEqual(stored?.username, "testuser")
    XCTAssertEqual(stored?.password, "testpass")
    XCTAssertEqual(stored?.version, "1.0")
    XCTAssertEqual(stored?.createdDate, createdDate)
    XCTAssertEqual(stored?.host?.url, "https://test.com")
    XCTAssertEqual(stored?.cloudid, "", "The unused Cloud ID should be dropped, it would take priority over the URL")
    XCTAssertEqual(realm.objects(HostDetails.self).count, 1)
  }
}
