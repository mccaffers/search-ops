// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class RealmTests: XCTestCase {
  
  @MainActor func testCreatingRealmOnDisk() throws {
    RealmManager().clearRealmInstance()
    
    let realm = RealmManager().getRealm()
    
    // Check if the file exists on disk
    XCTAssert(realm?.configuration.fileURL != nil)
    
    // Check the memory identifer
    XCTAssertNil(realm?.configuration.inMemoryIdentifier)
  }
  
  @MainActor func testCreatingRealmOnDiskInMemory() throws {
    RealmManager().clearRealmInstance()
    
    let realm = RealmManager().getRealm(inMemory: true)
    
    // Check if the file exists on disk
    XCTAssertNil(realm?.configuration.fileURL)
    
    // Check the memory identifer
    XCTAssert(realm?.configuration.inMemoryIdentifier != nil)
  }
  
  @MainActor func testCreatingRealmAlwaysFails() throws {
    RealmManager().clearRealmInstance()
    let mock = MockRealmClientAlwaysFails()
    let realm = RealmManager(realmClient: mock).getRealm()
    XCTAssertNil(realm)
  }
  
  @MainActor func testCreatingRealmWithDiscAccessIssues() throws {
    RealmManager().clearRealmInstance()
    let mock = MockRealmClientAlwaysFailsOnFile()
    let realm = RealmManager(realmClient: mock).getRealm()
    XCTAssert(realm != nil)

  }
  
}
