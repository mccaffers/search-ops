// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing
import RealmSwift

@testable import Search_Ops

/// A recent search as version 9 stored it, without field filters. Only the properties the test needs.
final class Version9SearchEvent: Object {
  override class func _realmObjectName() -> String? { "RealmSearchEvent" }
  // Kept out of every other realm, where it would clash with the real RealmSearchEvent
  override class func shouldIncludeInDefaultSchema() -> Bool { false }
  @Persisted(primaryKey: true) var id: UUID = UUID()
  @Persisted var index: String = ""
}

struct SearchHistoryMigrationTests {

  private let searchEventTypes: [ObjectBase.Type] = [
    RealmSearchEvent.self, RealmFilterObject.self, QueryObject.self, QueryFilterObject.self,
    RealmSquashedFieldsArray.self, RealmRelativeRangeFilter.self, RealmAbsoluteDateRangeObject.self,
    RealmSortObject.self, RealmFieldFilter.self
  ]

  private func withTemporaryFile(_ body: (URL) throws -> Void) throws {
    let fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("SearchHistoryMigrationTests-\(UUID().uuidString).realm")
    defer { _ = try? Realm.deleteFiles(for: Realm.Configuration(fileURL: fileURL)) }
    try body(fileURL)
  }

  @Test func schemaVersionIncludesFieldFilters() {
    #expect(RealmManager.schemaVersion >= 10)
  }

  @Test func version9SearchesOpenWithNoFieldFilters() throws {
    try withTemporaryFile { fileURL in
      let id = UUID()

      try autoreleasepool {
        let realm = try Realm(configuration: Realm.Configuration(fileURL: fileURL,
                                                                 schemaVersion: 9,
                                                                 objectTypes: [Version9SearchEvent.self]))
        let event = Version9SearchEvent()
        event.id = id
        event.index = "logs-*"
        try realm.write {
          realm.add(event)
        }
      }

      try autoreleasepool {
        let realm = try Realm(configuration: Realm.Configuration(fileURL: fileURL,
                                                                 schemaVersion: RealmManager.schemaVersion,
                                                                 migrationBlock: RealmManager.migrationBlock,
                                                                 objectTypes: searchEventTypes))
        let event = try #require(realm.object(ofType: RealmSearchEvent.self, forPrimaryKey: id))
        #expect(event.index == "logs-*")
        #expect(event.fieldFilters.isEmpty)

        try realm.write {
          event.fieldFilters.append(RealmFieldFilter(FieldFilter(field: "env", value: "demo", negated: true)))
        }
        #expect(event.fieldFilters.map { $0.eject() }.hasSameFilters(as: [FieldFilter(field: "env", value: "demo",
                                                                                      negated: true)]))
      }
    }
  }
}
