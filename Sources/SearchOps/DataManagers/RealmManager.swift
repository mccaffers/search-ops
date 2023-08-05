// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

enum MyError: Error {
		case runtimeError(String)
}

public class RealmManager {
	
	// Retrieve the existing encryption key for the app if it exists or create a new one
	private static func getKey() throws -> Data {
		// Identifier for our keychain entry - should be unique for your application
		let keychainIdentifier = "io.Realm.EncryptionExampleKey"
		let keychainIdentifierData = keychainIdentifier.data(using: String.Encoding.utf8, allowLossyConversion: false)!
		// First check in the keychain for an existing key
		var query: [NSString: AnyObject] = [
			kSecClass: kSecClassKey,
			kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
			kSecAttrKeySizeInBits: 512 as AnyObject,
			kSecReturnData: true as AnyObject
		]
		
		// To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
		// See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
		var dataTypeRef: AnyObject?
		var status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
		if status == errSecSuccess {
			// swiftlint:disable:next force_cast
			return dataTypeRef as! Data
		}
		// No pre-existing key from this application, so generate a new one
		// Generate a random encryption key
		var key = Data(count: 64)
		try key.withUnsafeMutableBytes({ (pointer: UnsafeMutableRawBufferPointer) in
			let result = SecRandomCopyBytes(kSecRandomDefault, 64, pointer.baseAddress!)
			if result != 0 {
				throw MyError.runtimeError("Failed to get random bytes")
			}
			assert(result == 0, "Failed to get random bytes")
		})
		// Store the key in the keychain
		query = [
			kSecClass: kSecClassKey,
			kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
			kSecAttrKeySizeInBits: 512 as AnyObject,
			kSecValueData: key as AnyObject
		]
		status = SecItemAdd(query as CFDictionary, nil)
		
		if status != errSecSuccess {
			throw MyError.runtimeError("Failed to insert the new key in the keychain")
		}
		
//		assert(status == errSecSuccess, "Failed to insert the new key in the keychain")
		return key
	}
	
	private static func getRealmConfig() -> Realm.Configuration {
		var config = Realm.Configuration()
		do {
			config = try Realm.Configuration(encryptionKey: getKey())
		} catch let error {
			print(error)
		}
		return config
	}
	
	public static func getRealm() -> Realm? {
		
		// Use the getKey() function to get the stored encryption key or create a new one
		var config = getRealmConfig()
		do {
			// Open the realm with the configuration
			let realm = try Realm(configuration: config)
			return realm
			// Use the realm as normal
		} catch let error as NSError {
			// If the encryption key is wrong, `error` will say that it's an invalid database
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
