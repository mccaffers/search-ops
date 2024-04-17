// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RealmManager {
  
  
  private static func getRealmConfig() -> Realm.Configuration {
    
    var config = Realm.Configuration(inMemoryIdentifier: UUID().uuidString, schemaVersion: 2)
    
    do {
      config = try Realm.Configuration(encryptionKey: RealmKeyManagement.GenerateOrGetKey(), schemaVersion: 2)
    } catch let error {
      print(error)
    }
   
    return config
    
  }

  
  @MainActor
  public static var realmInstance: Realm?
  
  @MainActor
  public static func getRealm(retry: Bool = false) -> Realm? {
    
    if realmInstance == nil {
      // Use the getKey() function to get the stored encryption key or create a new one
      let config = getRealmConfig()
      do {
        // Open the realm with the configuration
        print("Opening realm")
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
