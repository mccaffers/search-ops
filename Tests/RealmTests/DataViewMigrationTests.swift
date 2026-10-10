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

struct DataViewMigrationTests {

  private let hostTypes: [ObjectBase.Type] = [HostDetails.self, HostURL.self, Headers.self]
  private let dataViewTypes: [ObjectBase.Type] = [RealmDataView.self, RealmFieldLabel.self]

  private func config(_ fileURL: URL, version: UInt64, types: [ObjectBase.Type]) -> Realm.Configuration {
    return Realm.Configuration(fileURL: fileURL,
                               schemaVersion: version,
                               migrationBlock: RealmManager.migrationBlock,
                               objectTypes: types)
  }

  private func withTemporaryFile(_ body: (URL) throws -> Void) throws {
    let fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("DataViewMigrationTests-\(UUID().uuidString).realm")
    defer { _ = try? Realm.deleteFiles(for: Realm.Configuration(fileURL: fileURL)) }
    try body(fileURL)
  }

  @Test func version7HostsSurviveAndDataViewsStartEmpty() throws {
    try withTemporaryFile { fileURL in
      let hostId = UUID()

      try autoreleasepool {
        let realm = try Realm(configuration: config(fileURL, version: 7, types: hostTypes))
        let host = HostDetails()
        host.id = hostId
        host.name = "Trading"
        host.connectionType = .URL
        host.host?.url = "search.example.com"
        try realm.write {
          realm.add(host)
        }
      }

      try autoreleasepool {
        let realm = try Realm(configuration: config(fileURL, version: 8, types: hostTypes + dataViewTypes))
        let host = try #require(realm.object(ofType: HostDetails.self, forPrimaryKey: hostId))
        #expect(host.name == "Trading")
        #expect(host.host?.url == "search.example.com")
        #expect(realm.objects(RealmDataView.self).isEmpty)

        let view = RealmDataView(view: DataView(hostId: hostId,
                                                name: "Experiments",
                                                pattern: "backtesting-experiments-*",
                                                labels: ["durationSeconds": "Duration (s)"]))
        try realm.write {
          realm.add(view)
        }
      }

      try autoreleasepool {
        let realm = try Realm(configuration: config(fileURL, version: RealmManager.schemaVersion,
                                                    types: hostTypes + dataViewTypes))
        let stored = try #require(realm.objects(RealmDataView.self).first)
        #expect(stored.eject().labels == ["durationSeconds": "Duration (s)"])
      }
    }
  }

  @Test func schemaVersionIncludesDataViews() {
    #expect(RealmManager.schemaVersion >= 8)
  }

  // Older builds can't open a database once data views are added, so worth knowing if this changes
  @Test func version7CannotOpenVersion8File() throws {
    try withTemporaryFile { fileURL in
      try autoreleasepool {
        _ = try Realm(configuration: config(fileURL, version: 8, types: hostTypes + dataViewTypes))
      }
      autoreleasepool {
        #expect(throws: (any Error).self) {
          _ = try Realm(configuration: config(fileURL, version: 7, types: hostTypes))
        }
      }
    }
  }
}
