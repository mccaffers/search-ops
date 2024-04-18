//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 18/04/2024.
//

import Foundation
import RealmSwift

public class RealmClient: RealmClientProtocol {
  
  public init() { }
  
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    return try Realm(configuration: config)
  }
    
}

public class MockRealmClient: RealmClientProtocol {
  
  public init() { }
  
  public func getRealm(config: Realm.Configuration) throws -> Realm {
    throw MyError.runtimeError("ERROR")
  }
    
}

public protocol RealmClientProtocol {
  func getRealm(config: Realm.Configuration) throws -> Realm
}

