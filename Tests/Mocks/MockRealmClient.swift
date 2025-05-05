// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@testable import Search_Ops

// Documentation of common Realm error codes encountered in development:
// - Error Domain=io.realm Code=2: "Unable to open a realm at path" - Typically due to permission issues.
// - Error Domain=io.realm Code=3: "Failed to open file at path" - Operation not permitted.
// - Error Domain=io.realm Code=5: "Failed to open file at path" - Directory does not exist.
// - Error Domain=io.realm Code=20: "Failed to open Realm file at path" - Incorrect or missing encryption key.
// References:
// https://github.com/realm/realm-core/blob/master/src/realm/error_codes.cpp
// https://github.com/realm/realm-swift/blob/309003bb852df09585b8912720d3f6ee5023afbe/Realm/RLMError.mm

/// A mock implementation of `RealmClientProtocol` that always fails, simulating errors encountered when trying to open a Realm database.
public class MockRealmClientAlwaysFails: RealmClientProtocol {

  /// Initializes a new instance of the class.
  public init() {
    // Explicit public no-argument initializer to comply with Swift access control when used in other modules.
  }
  
  /// Simulates the failure to get a Realm instance by throwing an error.
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    throw NSError(domain: "realm.io", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to open a realm at path"])
  }
}

/// A mock `RealmClientProtocol` that fails only if the configuration does not specify an in-memory identifier, simulating file-related errors.
public class MockRealmClientAlwaysFailsOnFile: RealmClientProtocol {

  /// Initializes a new instance of the class.
  public init() {
    // Explicit public no-argument initializer to comply with Swift access control when used in other modules.
  }
  
  /// Attempts to get a Realm instance, throws an error if not in-memory configuration is provided.
  @MainActor
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    guard config.inMemoryIdentifier != nil else {
      let userInfo = [NSLocalizedDescriptionKey: "Failed to open Realm file due to invalid database", "RLMErrorCodeNameKey": "InvalidDatabase"]
      throw NSError(domain: "com.example.error", code: 0, userInfo: userInfo)
    }
    let realmInMemoryForTesting = Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                                                      schemaVersion: RealmManager.schemaVersion)
    return try Realm(configuration: realmInMemoryForTesting)
  }
}

/// A mock `RealmClientProtocol` that simulates encryption key failure when a Realm database is accessed without an in-memory identifier.
public class MockRealmClientEncryptionKeyFailed: RealmClientProtocol {

  var attempt = 0
  /// Initializes a new instance of the class.
  public init() {
    // Explicit public no-argument initializer to comply with Swift access control when used in other modules.
  }
  
  /// Attempts to get a Realm instance, throws an encryption key failure error if not an in-memory configuration.
  @MainActor
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    
    attempt+=1
    
    // Fail on the first two attempts (encryption key failed, sleep to retry)
    // Testing the flow when the encryption key is invalid
    if attempt < 3 {
      let userInfo = [NSLocalizedDescriptionKey: "Failed to open Realm file due to invalid database", "RLMErrorCodeNameKey": "InvalidEncryptionKey"]
      throw NSError(domain: "com.example.error", code: 0, userInfo: userInfo)
    }
   
    let realmInMemoryForTesting = Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                                                      schemaVersion: RealmManager.schemaVersion)
    return try Realm(configuration: realmInMemoryForTesting)

  }
}
