// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public class KeyGenerator : KeyGeneratorProtocol {
  
  public init(){}
  
  public func Generate() throws -> Data {
    
    var keyData = Data(count: 64)
    let result = keyData.withUnsafeMutableBytes {
      SecRandomCopyBytes(kSecRandomDefault, 64, $0.baseAddress!)
    }
    
    if result == errSecSuccess {
      return keyData
    } else {
      print("Problem generating random bytes")
      throw KeyGeneratorError.failedToGenerate
    }
  }
  
}

