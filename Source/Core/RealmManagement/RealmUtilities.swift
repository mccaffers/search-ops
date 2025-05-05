// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public protocol RealmUtilitiesProtocol {
  func deleteRealmDatabase() throws
}


public class RealmUtilities : RealmUtilitiesProtocol {
  
  public init(){}
  
  public func deleteRealmDatabase() throws {
    print("Deleting realm instance")
    let realmURL = Realm.Configuration.defaultConfiguration.fileURL!
    let realmURLs = [
      realmURL,
      realmURL.appendingPathExtension("lock"),
      realmURL.appendingPathExtension("note"),
      realmURL.appendingPathExtension("management"),
    ]
    for URL in realmURLs {
      let response = try? FileManager.default.removeItem(at: URL)
      print(response ?? "")
    }
    
  }
  
}
