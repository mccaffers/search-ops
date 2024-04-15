//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 14/04/2024.
//

import Foundation

public class KeyGenerator {
  
  public static func New() throws -> Data {
    
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
