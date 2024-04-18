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
    let legacyKey = LegacyKeychainManager().RetrieveLegacyKeychain()
    return legacyKey != nil
  }
  
  public static func performMigrationIfNecessary() -> (success:Bool, error:Error?) {
    // Check if key in kSecClassKey, save as kSecClassGenericPassword instead
    // for compatability between iOS and macOS
    let legacyKey = LegacyKeychainManager().RetrieveLegacyKeychain()
    
    // If the key exists in the legacy keychain, delete it, add it again
    if(legacyKey != nil){
      // migrate
      LegacyKeychainManager().DeleteLegacyKeychain()
      do {
        try KeychainManager().Add(input:legacyKey)
      } catch let error {
        return (false, error)
      }
    }
    
    return (true, nil)
  }
  
}
