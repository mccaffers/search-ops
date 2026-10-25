// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

// Mock class implementing KeychainManagerProtocol
public class MockKeychainManager: KeychainManagerProtocol {
  
  var key: Data? = nil
  var addThrowsError: Error? = nil
  var readThrowsError: Error? = nil
  var addCalledCount = 0
  
  public func read() throws -> Data {
    if let error = readThrowsError {
      throw error
    }
    guard let key else {
      throw KeychainManagerError.noItemFound
    }
    return key
  }
  
  public func query() -> Data? {
    return try? read()
  }
  
  public func add(input: Data?) throws -> Data? {
    addCalledCount += 1
    if let error = addThrowsError {
      throw error
    }
    
    self.key = try input ?? KeyGenerator().Generate()
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
      XCTAssertEqual(keychainMock.key, key)
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
    
    // The add failed, so the legacy key must still be there for the next launch to retry
    XCTAssertEqual(legacyMock.key, key)
    XCTAssertNil(keychainMock.key)
    XCTAssertFalse(response.success)
    XCTAssertEqual(response.error as! KeychainManagerError, KeychainManagerError.unhandledError(status: 1))

  }
  
  // RealmManager already opens the realm with a key in the new format, so neither key changes
  func testExistingKeyInNewFormatIsKept() throws {
    let legacyMock = MockLegacyKeychainManager()
    try legacyMock.addLegacyKeychain()
    let legacyKey = legacyMock.key
    
    let keychainMock = MockKeychainManager()
    let existing = try KeyGenerator().Generate()
    keychainMock.key = existing
    
    let response = RealmMigration(legacyKeychainManager: legacyMock, keychainManager: keychainMock).performMigrationIfNecessary()
    
    XCTAssertTrue(response.success)
    XCTAssertEqual(keychainMock.key, existing)
    XCTAssertEqual(keychainMock.addCalledCount, 0)
    XCTAssertEqual(legacyMock.key, legacyKey)
  }
  
  // Can't tell whether a key in the new format exists, so nothing changes and the next launch retries
  func testNewFormatReadFailureChangesNothing() throws {
    let legacyMock = MockLegacyKeychainManager()
    try legacyMock.addLegacyKeychain()
    let legacyKey = legacyMock.key
    
    let keychainMock = MockKeychainManager()
    keychainMock.readThrowsError = KeychainManagerError.unhandledError(status: errSecInteractionNotAllowed)
    
    let response = RealmMigration(legacyKeychainManager: legacyMock, keychainManager: keychainMock).performMigrationIfNecessary()
    
    XCTAssertFalse(response.success)
    XCTAssertEqual(response.error as? KeychainManagerError, KeychainManagerError.unhandledError(status: errSecInteractionNotAllowed))
    XCTAssertEqual(keychainMock.addCalledCount, 0)
    XCTAssertEqual(legacyMock.key, legacyKey)
  }

}
