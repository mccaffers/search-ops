// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

// Mock class implementing KeychainManagerProtocol
public class MockKeychainManager: KeychainManagerProtocol {
  
  var key: Data? = nil
  var addThrowsError: Error? = nil
  public func query() -> Data? {
    return key
  }
  
  public func add(input: Data?) throws -> Data? {
    if let error = addThrowsError {
      throw error
    }
    
    self.key = input
    return key
  }
  
  public func delete() throws {
    self.key = nil
  }
}

// Mock class implementing LegacyKeychainManagerProtocol
public class MockLegacyKeychainManager: LegacyKeychainManagerProtocol {
  
  var key: Data? = nil
  
  public func retrieveLegacyKeychain() -> Data? {
    return key
  }
  
  public func deleteLegacyKeychain() -> Bool {
    key = nil
    return true
  }
  
  @discardableResult
  public func addLegacyKeychain() throws -> Data? {
    self.key = try KeyGenerator().Generate()
    return self.key
  }
  
}


final class RealmMigrationTests: XCTestCase {

  
    func testPassingTheKeyBetweenKeychains() throws {
            
      var legacyMock = MockLegacyKeychainManager()
      try legacyMock.addLegacyKeychain()
      var key = legacyMock.key
      XCTAssertNotNil(key)
      
      var keychainMock = MockKeychainManager()
      
      let realmMigrationClient = RealmMigration(legacyKeychainManager: legacyMock, keychainManager: keychainMock)
      let response = realmMigrationClient.performMigrationIfNecessary()
      
      // Legacy key is deleted, and added to the main keychain
      XCTAssertNil(legacyMock.key)
      XCTAssertNotNil(keychainMock.key)
      XCTAssertTrue(response.success)
      XCTAssertNil(response.error)

    }
  
  func testEmptyLegacyKey() throws {
          
    var legacyMock = MockLegacyKeychainManager()
    XCTAssertNil(legacyMock.key)
    
    var keychainMock = MockKeychainManager()
    
    let realmMigrationClient = RealmMigration(legacyKeychainManager: legacyMock, keychainManager: keychainMock)
    let response = realmMigrationClient.performMigrationIfNecessary()
    
    // No keys are added to the keychain
    XCTAssertNil(legacyMock.key)
    XCTAssertNil(keychainMock.key)
    
    XCTAssertTrue(response.success)
    XCTAssertNil(response.error)

  }
  
  func testEmptyMainKeychainThrow() throws {
          
    var legacyMock = MockLegacyKeychainManager()
    try legacyMock.addLegacyKeychain()
    var key = legacyMock.key
    XCTAssertNotNil(key)
    
    var keychainMock = MockKeychainManager()
    keychainMock.addThrowsError = KeychainManagerError.unhandledError(status: 1)
    
    let realmMigrationClient = RealmMigration(legacyKeychainManager: legacyMock, keychainManager: keychainMock)
    let response = realmMigrationClient.performMigrationIfNecessary()
    
    // Legacy key is deleted, and added to the main keychain
    XCTAssertNil(legacyMock.key)
    XCTAssertNil(keychainMock.key)
    XCTAssertFalse(response.success)
    XCTAssertEqual(response.error as! KeychainManagerError, KeychainManagerError.unhandledError(status: 1))

  }

 

}
