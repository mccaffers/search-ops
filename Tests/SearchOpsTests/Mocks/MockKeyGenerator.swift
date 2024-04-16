// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

import SearchOps

public class MockKeyGeneratorFailure : KeyGeneratorProtocol {
  
  public init(){}
    
  public func Generate() throws -> Data {
    throw KeyGeneratorError.failedToGenerate
  }
}

public class MockKeyGeneratorValidResponse : KeyGeneratorProtocol {
  
  public init(){}
    
  public func Generate() throws -> Data {
    return Data(count: 64)
  }
}

public class MockKeyGeneratorIncorrectSize : KeyGeneratorProtocol {
  
  public init(){}
    
  public func Generate() throws -> Data {
    return Data(count: 65)
  }
}
