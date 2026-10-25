// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

public class RealmUtilitiesMock : RealmUtilitiesProtocol {
  var deleteCalledCount = 0
  
  public func deleteRealmDatabase() throws {
    deleteCalledCount+=1
  }
  
}

final class RealmTests: XCTestCase {
  
  @MainActor
  override func setUp() {
    RealmManager().clearRealmInstance()
  }
  
  @MainActor
  func testCreatingRealmOnDisk() throws {
    // An on-disk realm needs the encryption key from the Keychain, which unsigned runs keep away from
    try XCTSkipIf(RealmManager().inMemoryStoreRequested,
                  "\(RealmManager.inMemoryStoreVariable) is set, so the realm stays in memory")

    let realm = RealmManager().getRealm()
    
    // Check if the file exists on disk
    XCTAssert(realm?.configuration.fileURL != nil)
    
    // Check the memory identifer
    XCTAssertNil(realm?.configuration.inMemoryIdentifier)
  }
  
  @MainActor func testCreatingRealmOnDiskInMemory() throws {
    let realm = RealmManager().getRealm(inMemory: true)
    
    // Check if the file exists on disk
    XCTAssertNil(realm?.configuration.fileURL)
    
    // Check the memory identifer
    XCTAssert(realm?.configuration.inMemoryIdentifier != nil)
  }
  
  @MainActor func testInMemoryStoreFlagKeepsRealmInMemory() throws {
    let manager = RealmManager(environment: [RealmManager.inMemoryStoreVariable: "1"])
    XCTAssertTrue(manager.inMemoryStoreRequested)

    let realm = manager.getRealm()

    // No file on disk, so no encryption key was needed from the Keychain
    XCTAssertNil(realm?.configuration.fileURL)
    XCTAssertNotNil(realm?.configuration.inMemoryIdentifier)
    XCTAssertNil(realm?.configuration.encryptionKey)
    // Asking for memory isn't a missing key, so no alert
    XCTAssertFalse(RealmManager.keyUnavailable)
  }

  @MainActor func testInMemoryStoreFlagOnlyAcceptsOne() throws {
    XCTAssertFalse(RealmManager(environment: [:]).inMemoryStoreRequested)
    XCTAssertFalse(RealmManager(environment: [RealmManager.inMemoryStoreVariable: "0"]).inMemoryStoreRequested)
    XCTAssertFalse(RealmManager(environment: [RealmManager.inMemoryStoreVariable: "true"]).inMemoryStoreRequested)
  }

  @MainActor func testCreatingRealmAlwaysFails() throws {
    let mock = MockRealmClientAlwaysFails()
    let realm = RealmManager(realmClient: mock).getRealm()
    XCTAssertNil(realm)
  }
  
  @MainActor func testCreatingRealmWithDiscAccessIssues() throws {
    let mock = MockRealmClientAlwaysFailsOnFile()
    let realm = RealmManager(realmClient: mock).getRealm()
    XCTAssert(realm != nil)

  }
  
  @MainActor func testCreatingRealmWithKeyIssues() throws {

    let realmClientMock = MockRealmClientEncryptionKeyFailed()
    var realUtilitiesMock = RealmUtilitiesMock()
    
    let realm = RealmManager(realmClient: realmClientMock,
                             realmUtilities: realUtilitiesMock).getRealm()
    
    
    XCTAssert(realm != nil)
    XCTAssertEqual(realUtilitiesMock.deleteCalledCount, 1)

  }
  
  // eg. the user pressed Deny on the Keychain prompt: run in memory, and keep the realm on disk for next time
  // The on-disk realm fails as InvalidDatabase, which would delete it if the manager ever tried to open it
  @MainActor func testKeyUnavailableLoadsInMemoryWithoutDeleting() throws {
    let realmClientMock = MockRealmClientAlwaysFailsOnFile()
    let realmUtilitiesMock = RealmUtilitiesMock()
    
    let realm = RealmManager(realmClient: realmClientMock,
                             realmUtilities: realmUtilitiesMock,
                             keyManagement: MockRealmKeyManagementUnavailable(),
                             environment: [:]).getRealm()
    
    XCTAssertNotNil(realm?.configuration.inMemoryIdentifier)
    XCTAssertNil(realm?.configuration.fileURL)
    XCTAssertEqual(realmUtilitiesMock.deleteCalledCount, 0)
    // Tells the root views to show the "Couldn't Load Your Data" alert
    XCTAssertTrue(RealmManager.keyUnavailable)
    
    // Clearing the instance clears the flag, so the next realm starts afresh
    RealmManager().clearRealmInstance()
    XCTAssertFalse(RealmManager.keyUnavailable)
  }
  
}

public class MockRealmKeyManagementUnavailable : RealmKeyManagementProtocol {
  public func generateOrGetKey() throws -> Data {
    throw KeychainManagerError.unhandledError(status: errSecAuthFailed)
  }
  
}
