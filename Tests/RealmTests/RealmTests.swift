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
  
}
