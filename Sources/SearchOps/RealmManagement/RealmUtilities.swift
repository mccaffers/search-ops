// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RealmUtilities {
  
  public static func DeleteRealmDatabase() throws {
    try? FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
  }
  
}
