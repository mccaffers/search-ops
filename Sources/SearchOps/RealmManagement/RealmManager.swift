// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RealmManager {
  
  @MainActor
  private static var realmInstance: Realm?
  
  private static let schemaVersion : UInt64 = 2
  
  private static func getRealmConfig() -> Realm.Configuration {
    
    do {
      return try Realm.Configuration(encryptionKey: RealmKeyManagement.GenerateOrGetKey(), schemaVersion: schemaVersion)
    } catch let error {
      print(error)
      return Realm.Configuration(schemaVersion: schemaVersion)
    }
    
  }
  
  private static func getRealmConfigInMemory() -> Realm.Configuration {
    return Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                               schemaVersion: schemaVersion)
  }
  
  @MainActor
  public static func clearRealmInstance() {
    realmInstance = nil
  }
  
  @MainActor
  public static func getRealm(retry: Bool = false, 
                              inMemory: Bool = false) -> Realm? {
    
    var config: Realm.Configuration
    
    if let realmInstance = realmInstance {
      print("realm instance exists")
      return realmInstance
    }
    
    // Use the getKey() function to get the stored encryption key or create a new one
    if inMemory {
      config = getRealmConfigInMemory()
    } else {
      config = getRealmConfig()
    }
    
    print("Opening realm")
    
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
      try! RealmUtilities.DeleteRealmDatabase()
      
      if !retry {
        sleep(1)
        return getRealm(retry: true)
      }
      fatalError("Error opening realm: \(error)")
      
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
