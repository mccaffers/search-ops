//
//  KeychainManagerTests.swift
//  
//
//  Created by Ryan McCaffery on 15/04/2024.
//

import XCTest

@testable import SearchOps

final class KeychainManagerTests: XCTestCase {


    func testExample() throws {
        let keychainOps = MockKeychainOperations()
      
      let query = [kSecClass as String: kSecClassGenericPassword as String]
                                                          as [String : Any]
      
      XCTAssertThrowsError(try keychainOps.SecItemCopyMatching(query: query)) { error in
            XCTAssertEqual(error as! KeychainManagerError,  KeychainManagerError.noItemFound)
        }
    }

}
