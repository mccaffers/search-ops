// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@testable import SearchOps

// Realm Error Codes
// https://github.com/realm/realm-core/blob/master/src/realm/error_codes.cpp
// https://github.com/realm/realm-swift/blob/309003bb852df09585b8912720d3f6ee5023afbe/Realm/RLMError.mm

// Common ones I've seen:
// Error Domain=io.realm Code=2 "Unable to open a realm at path" - Permissions
// Error Domain=io.realm Code=3 "Failed to open file at path" - Operation not permitted
// Error Domain=io.realm Code=5 "Failed to open file at path" - Directory doesn't exist
// Error Domain=io.realm Code=20 "Failed to open Realm file at path" - Encryption key failed - InvalidDatabase

public class MockRealmClientAlwaysFails: RealmClientProtocol {
  
  // From Apple Documentation,
  // For a type that’s defined as public, the default initializer is considered internal.
  // If you want a public type to be initializable with a no-argument initializer when used in another module,
  // you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
  // Source: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
  
  public init() {
    // SonarCloud - swift:S1186
  }
  
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    let error = NSError(domain: "realm.io", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to open a realm at path"])
    throw error
  }
    
}

public class MockRealmClientAlwaysFailsOnFile: RealmClientProtocol {
  
  // From Apple Documentation,
  // For a type that’s defined as public, the default initializer is considered internal.
  // If you want a public type to be initializable with a no-argument initializer when used in another module,
  // you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
  // Source: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
  
  public init() {
    // SonarCloud - swift:S1186
  }
  
  @MainActor
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    if config.inMemoryIdentifier == nil {
      
      let query = [NSLocalizedDescriptionKey as String: "Reason",
                   "RLMDeprecatedErrorCodeKey": "0",
                   "RLMErrorCodeNameKey": "InvalidDatabase"] as [String : Any]
      
      let error = NSError(domain: "com.example.error", code: 0, userInfo: query);
       
      throw error
    } else {
      return RealmManager().getRealm(inMemory: true)!
    }
  }
}

public class MockRealmClientEncryptionKeyFailed: RealmClientProtocol {
  
  // From Apple Documentation,
  // For a type that’s defined as public, the default initializer is considered internal.
  // If you want a public type to be initializable with a no-argument initializer when used in another module,
  // you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
  // Source: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
  
  public init() {
    // SonarCloud - swift:S1186
  }
  
  @MainActor
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    if config.inMemoryIdentifier == nil {
      let error = NSError(domain: "realm.io", code: 0, userInfo: [NSLocalizedDescriptionKey : "Encryption key failed"])
      throw error
    } else {
      return RealmManager().getRealm(inMemory: true)!
    }
  }
}

