// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps


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
