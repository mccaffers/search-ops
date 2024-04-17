//
//  RealmTests.swift
//  
//
//  Created by Ryan McCaffery on 17/04/2024.
//

import XCTest

@testable import SearchOps

final class RealmTests: XCTestCase {

  @MainActor func testCreatingRealm() throws {
      let realm = RealmManager.getRealm()
    }


}
