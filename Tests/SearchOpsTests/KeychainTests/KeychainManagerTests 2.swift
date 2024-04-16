//
//  KeychainManagerTests 2.swift
//  
//
//  Created by Ryan McCaffery on 16/04/2024.
//

import XCTest

@testable import SearchOps


final class KeychainManagerTests_2: XCTestCase {

    override func setUpWithError() throws {
        try? RealmManager.DeleteRealmDatabase()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
