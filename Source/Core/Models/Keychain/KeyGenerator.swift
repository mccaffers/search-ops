// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public class KeyGenerator : KeyGeneratorProtocol {
  
  public init() {
    // For a type that’s defined as public, the default initializer is considered internal.
    // If you want a public type to be initializable with a no-argument initializer when used in another module,
    // you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
    // https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
    // SonarCloud - swift:S1186
  }
  
  public func Generate() throws -> Data {
    
    var keyData = Data(count: 64)
    let result = keyData.withUnsafeMutableBytes {
      SecRandomCopyBytes(kSecRandomDefault, 64, $0.baseAddress!)
    }
    
    if result == errSecSuccess {
      SystemLogger().message("Generating a new encryption key for local realm database using Apple.Security (SecRandomCopyBytes)", level:.info)
      return keyData
    } else {
      SystemLogger().message("There was a problem generating random bytes (SecRandomCopyBytes)", level:.warn)
      throw KeyGeneratorError.failedToGenerate
    }
  }
  
}

