// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@testable import SearchOps

public class MockRealmClientAlwaysFails: RealmClientProtocol {
  
  public init() { }
  
  // Realm Error Codes
  // https://github.com/realm/realm-core/blob/master/src/realm/error_codes.cpp
  
  // Common ones I've seen:
  // Error Domain=io.realm Code=2 "Unable to open a realm at path" - Permissions
  // Error Domain=io.realm Code=3 "Failed to open file at path" - Operation not permitted
  // Error Domain=io.realm Code=5 "Failed to open file at path" - Directory doesn't exist
  // Error Domain=io.realm Code=20 "Failed to open Realm file at path" - Encryption key failed
  
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    let error = NSError(domain: "realm.io", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to open a realm at path"])
    throw error
  }
    
}


public class MockRealmClientAlwaysFailsOnFile: RealmClientProtocol {
  
  public init() { }
  
  @MainActor
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    if config.inMemoryIdentifier == nil {
      let error = NSError(domain: "realm.io", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to open a realm at path"])
      throw error
    } else {
      return RealmManager().getRealm(inMemory: true)!
    }
  }
}
