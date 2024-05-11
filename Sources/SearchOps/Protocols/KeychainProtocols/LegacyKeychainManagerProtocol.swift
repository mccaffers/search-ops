import Foundation

public protocol LegacyKeychainManagerProtocol {
  func retrieveLegacyKeychain() -> Data?
  func deleteLegacyKeychain() -> Bool
  func addLegacyKeychain() throws -> Data?
}




