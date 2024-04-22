// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// `RealmMigration` manages the migration of keychain storage mechanisms to enhance compatibility across different iOS and macOS versions.
public class RealmMigration {

  /// Checks if migration is necessary by determining the presence of legacy keychain items.
  /// - Returns: A Boolean indicating whether a legacy keychain item exists that requires migration.
  public static func isMigrationNecessary() -> Bool {
    // Retrieve the legacy keychain item. This item is checked to see if it's using older keychain classes.
    let legacyKey = LegacyKeychainManager().retrieveLegacyKeychain()
    return legacyKey != nil  // Returns true if there is a legacy keychain item, indicating migration is necessary.
  }
  
  /// Performs the migration if it is necessary by transferring data from a legacy keychain class to a more compatible class.
  /// - Returns: A tuple containing a boolean indicating success and an optional error if the migration fails.
  public static func performMigrationIfNecessary() -> (success: Bool, error: Error?) {
    // First, check if there is a legacy keychain item that needs to be migrated.
    if let legacyKey = LegacyKeychainManager().retrieveLegacyKeychain() {
      // Attempt to delete the old legacy keychain item to prevent duplicate data.
      _ = LegacyKeychainManager().deleteLegacyKeychain()
      
      do {
        // Attempt to add the retrieved item to the new keychain class which is more compatible across iOS and macOS.
        try KeychainManager().Add(input: legacyKey)
      } catch let error {
        // Return false and the error if the migration process fails during the addition of the new keychain item.
        return (false, error)
      }
    }
    
    // If there was no legacy key or the migration was successful, return true with no error.
    return (true, nil)
  }
}
