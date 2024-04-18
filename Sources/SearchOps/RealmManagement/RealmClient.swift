// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RealmClient: RealmClientProtocol {
  
  // From Apple Documentation,
  // For a type that’s defined as public, the default initializer is considered internal.
  // If you want a public type to be initializable with a no-argument initializer when used in another module,
  // you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
  // Source: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
  
  public init() {
    // SonarCloud - swift:S1186
  }
  
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    return try Realm(configuration: config)
  }
    
}



