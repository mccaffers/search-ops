// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RealmKeyManagement {
  // Retrieve the existing encryption key for the app if it exists or create a new one
  public static func generateOrGetKey() throws -> Data? {
    
    var key : Data?
    
    // Double check it exists
    let outcome = KeychainManager().query()
    
    // Success! Realm key exists in the keychain, lets return the key
    if outcome != nil{
      SystemLogger().message("Found an encryption key in the Keychain")
      return outcome!
    }
    
    SystemLogger().message("No encryption key found in Keychain")
    // If not, lets generate a key and add it to the keychain
    do {
      // KeyGenerator can throw
      // SecAddItem can throw
      key = try KeychainManager().add()
    } catch let error {
      print(error)
    }
    
    // If we get this far, there has been a problem
    // but realm will continue with encyrption turned off
    // but we need to notify the users, maybe with the option of retry?
    return key
  }
 
}
