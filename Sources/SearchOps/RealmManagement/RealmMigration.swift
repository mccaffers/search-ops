// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RealmMigration {
  
  public static func isMigrationNecessary() -> Bool {
    // Check if key in kSecClassKey, save as kSecClassGenericPassword instead
    // for compatability between iOS and macOS
    let legacyKey = LegacyKeychainManager().retrieveLegacyKeychain()
    return legacyKey != nil
  }
  
  public static func performMigrationIfNecessary() -> (success:Bool, error:Error?) {
    // Check if key in kSecClassKey, save as kSecClassGenericPassword instead
    // for compatability between iOS and macOS
    if let legacyKey = LegacyKeychainManager().retrieveLegacyKeychain() {
      _ = LegacyKeychainManager().deleteLegacyKeychain()
      do {
        try KeychainManager().Add(input:legacyKey)
      } catch let error {
        return (false, error)
      }
    }
    
    return (true, nil)
  }
  
}
