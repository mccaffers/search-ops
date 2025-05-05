// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@testable import Search_Ops

/// A mock implementation of `KeyGeneratorProtocol` designed to simulate a failure in key generation.
/// This class can be used in testing to verify how the system handles errors during the key generation process.
public class MockKeyGeneratorFailure : KeyGeneratorProtocol {
  
  /// Initializes a new instance of the class.
  public init(){}
  
  /// Simulates a failure in generating a cryptographic key by throwing a `KeyGeneratorError.failedToGenerate` error.
  /// - Throws: `KeyGeneratorError.failedToGenerate` to simulate a failure in key generation.
  public func Generate() throws -> Data {
    throw KeyGeneratorError.failedToGenerate
  }
}

/// A mock implementation of `KeyGeneratorProtocol` that always generates a valid key of the correct size.
/// This class can be used in testing to ensure that the system correctly handles a successful key generation.
public class MockKeyGeneratorValidResponse : KeyGeneratorProtocol {
  
  /// Initializes a new instance of the class.
  public init(){}
  
  /// Simulates the successful generation of a cryptographic key.
  /// - Returns: A `Data` object containing a 64-byte key.
  public func Generate() throws -> Data {
    return Data(count: 64)  // Returns a valid 64 bytes key.
  }
}

/// A mock implementation of `KeyGeneratorProtocol` that generates a key of incorrect size.
/// This class can be used in testing to check how the system responds to key sizes that do not meet expected criteria.
public class MockKeyGeneratorIncorrectSize : KeyGeneratorProtocol {
  
  /// Initializes a new instance of the class.
  public init(){}
  
  /// Simulates the generation of a cryptographic key that is of incorrect size.
  /// - Returns: A `Data` object containing a 65-byte key, which is incorrect as per typical cryptographic standards requiring 64 bytes.
  public func Generate() throws -> Data {
    return Data(count: 65)  // Returns an incorrect size key of 65 bytes.
  }
}
