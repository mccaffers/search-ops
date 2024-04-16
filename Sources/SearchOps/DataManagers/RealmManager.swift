// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RealmManager {
  
  public static func IsMigrationNecessary() -> Bool {
    // Check if key in kSecClassKey, save as kSecClassGenericPassword instead
    // for compatability between iOS and macOS
    let legacyKey = LegacyKeychainManager().RetrieveLegacyKeychain()
    return legacyKey != nil
  }
  
  public static func PerformMigrationIfNecessary() -> (success:Bool, error:Error?) {
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
  

  // Retrieve the existing encryption key for the app if it exists or create a new one
  private static func GenerateOrGetKey() throws -> Data? {
    
    var key : Data?
    
    // Double check it exists
    let outcome = KeychainManager().Query()
    
    // Success! Key exists in the keychain, lets return the key
    if outcome != nil{
      return outcome!
    } else {
      // If not, lets generate a key and add it to the keychain
      do {
        key = try KeychainManager().Add()
      } catch let error {
        print(error)
      }
    }
    
    // If we get this far, there has been a problem
    // but realm will continue with encyrption turned off
    // Need to notify the usere
    return key
  }
  
  private static func getKeyMacOS() throws -> Data {
    return Data()
  }
  
  private static func getRealmConfig() -> Realm.Configuration {
    
    var config = Realm.Configuration(schemaVersion: 2)
    
    do {
      config = try Realm.Configuration(encryptionKey: GenerateOrGetKey(), schemaVersion: 2)
    } catch let error {
      print(error)
    }
   
    return config
    
  }
  
  public static func DeleteRealmDatabase() throws {
    // Not avaliable to users yet
    try? FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
  }
  
  @MainActor
  public static var realmInstance: Realm?
  
  @MainActor
  public static func getRealm() -> Realm? {
    
    if realmInstance == nil {
      // Use the getKey() function to get the stored encryption key or create a new one
      let config = getRealmConfig()
      do {
        // Open the realm with the configuration
        realmInstance = try Realm(configuration: config)
        return realmInstance
        // Use the realm as normal
      } catch let error as NSError {
        // If the encryption key is wrong, `error` will say that it's an invalid database
        
        // TODO
        // Need to inform the user. This is unlikely to happen unless the keychain gets tampered with
        // and then you cannot open the realm database
        print("Deleting database")
        try! DeleteRealmDatabase()
        
        fatalError("Error opening realm: \(error)")
        
      }
    } else {
      return realmInstance
    }
    
  }
  
  public static func checkRealmFileSize() -> Double{
    
    if let realmPath = Realm.Configuration.defaultConfiguration.fileURL?.relativePath {
      do {
        let attributes = try FileManager.default.attributesOfItem(atPath:realmPath)
        if let fileSize = attributes[FileAttributeKey.size] as? Double {
          
          return fileSize / 1000000.0
        }
      }
      catch (let error) {
        print("FileManager Error: \(error)")
      }
    }
    
    return 0.0
  }
}
