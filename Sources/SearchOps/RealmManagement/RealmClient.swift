//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 18/04/2024.
//

import Foundation
import RealmSwift

public class RealmClient: RealmClientProtocol {
  
  public init() {
    // Required to create a public initialiser
    // For a type that’s defined as public, the default initializer is considered internal.
    // If you want a public type to be initializable with a no-argument initializer when used in another module, you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
    // https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
    // SonarCloud - swift:S1186
  }
  
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    return try Realm(configuration: config)
  }
    
}



