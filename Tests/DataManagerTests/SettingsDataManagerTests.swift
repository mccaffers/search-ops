// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Foundation
import RealmSwift

@testable import Search_Ops

@available(macOS 13.0, *)
@available(iOS 15.0, *)
final class SettingsDataManagerTests: XCTestCase {

  @MainActor
  override func setUp() {
    super.setUp()
    _ = RealmManager().getRealm(inMemory: true)
  }

  func testParseDocumentsPerPageAcceptsWholeNumbersInRange() {
    XCTAssertEqual(SettingsDataManager.parseDocumentsPerPage("1"), 1)
    XCTAssertEqual(SettingsDataManager.parseDocumentsPerPage("25"), 25)
    XCTAssertEqual(SettingsDataManager.parseDocumentsPerPage(" 100 "), 100)
    XCTAssertEqual(SettingsDataManager.parseDocumentsPerPage("10000"), 10_000)
  }

  func testParseDocumentsPerPageRejectsInvalidInput() {
    XCTAssertNil(SettingsDataManager.parseDocumentsPerPage(""))
    XCTAssertNil(SettingsDataManager.parseDocumentsPerPage("0"))
    XCTAssertNil(SettingsDataManager.parseDocumentsPerPage("-5"))
    XCTAssertNil(SettingsDataManager.parseDocumentsPerPage("10001"))
    XCTAssertNil(SettingsDataManager.parseDocumentsPerPage("2.5"))
    XCTAssertNil(SettingsDataManager.parseDocumentsPerPage("abc"))
  }

  func testDocumentsPerPagePresetMatchesOnlyPresetValues() {
    XCTAssertEqual(SettingsDataManager.documentsPerPagePresets, [25, 50, 100, 200])
    for preset in SettingsDataManager.documentsPerPagePresets {
      XCTAssertEqual(SettingsDataManager.documentsPerPagePreset(matching: preset), preset)
    }
    XCTAssertNil(SettingsDataManager.documentsPerPagePreset(matching: 1))
    XCTAssertNil(SettingsDataManager.documentsPerPagePreset(matching: 75))
    XCTAssertNil(SettingsDataManager.documentsPerPagePreset(matching: 10_000))
  }

  @MainActor
  func testDocumentsPerPageDefaultsAndPersists() {
    let manager = SettingsDataManager()
    manager.setDocumentsPerPage(input: SettingsDataManager.defaultDocumentsPerPage)
    XCTAssertEqual(manager.documentsPerPage, 25)

    manager.setDocumentsPerPage(input: 100)

    // A fresh manager reads the saved value back from the database, as the search request does
    XCTAssertEqual(SettingsDataManager().documentsPerPage, 100)

    manager.setDocumentsPerPage(input: SettingsDataManager.defaultDocumentsPerPage)
  }
}
