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
    
    var key = Data(count: 64)
    
    try key.withUnsafeMutableBytes({ (pointer: UnsafeMutableRawBufferPointer) in
      
      guard SecRandomCopyBytes(kSecRandomDefault, 64, pointer.baseAddress!) != 0 else {
        throw MyError.runtimeError("Failed to get random bytes")
      }
      
    })

    print(key.map { String(format: "%02x", $0) }.joined())

    return key
    
  }
}
