// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@testable import SearchOps

public class MockRealmClient: RealmClientProtocol {
  
  public init() { }
  
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    
    // Error Domain=io.realm Code=2 "Unable to open a realm at path" - Permissions
    // Error Domain=io.realm Code=3 "Failed to open file at path" - Operation not permitted
    // Error Domain=io.realm Code=5 "Failed to open file at path" - Directory doesn't exist
    throw MyError.runtimeError("ERROR")
  }
    
}
