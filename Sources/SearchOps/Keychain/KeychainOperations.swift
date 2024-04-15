//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 15/04/2024.
//

import Foundation

public enum KeychainManagerError: Error, Equatable {
    case noItemFound
    case unexpectedData
    case unhandledError(status: OSStatus)
}

public protocol KeychainOperationsProtocol {
  func SecItemCopyMatching(query:[String : Any]) throws -> Data
  func SecItemAdd(query:[String:Any]) throws -> Bool
}


public class MockKeychainOperations : KeychainOperationsProtocol {
  public func SecItemCopyMatching(query: [String : Any]) throws -> Data {
    throw KeychainManagerError.noItemFound
  }
  
  public func SecItemAdd(query: [String : Any]) throws -> Bool {
    throw KeychainManagerError.noItemFound
  }
  
}
  
public class KeychainOperations : KeychainOperationsProtocol {
  
  public init(){
    
  }
  
  public func SecItemCopyMatching(query:[String : Any]) throws -> Data {
    var item: AnyObject? = nil
    let status: OSStatus = Security.SecItemCopyMatching(query as CFDictionary, &item)
    
    // Check the return status and throw an error if appropriate.
    guard status != errSecItemNotFound else {
      throw KeychainManagerError.noItemFound
    }
    
    guard status == noErr else {
      throw KeychainManagerError.unhandledError(status: status)
    }
    
    // Parse the string value from the query result.
    guard let existingItem = item as? [String: AnyObject],
          let data = existingItem[kSecValueData as String] as? Data else {
      throw KeychainManagerError.unexpectedData
    }
      
    return data
  }
  
  public func SecItemAdd(query:[String:Any]) throws -> Bool {
    let status = Security.SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      return false
    }
    return true
  }
}
