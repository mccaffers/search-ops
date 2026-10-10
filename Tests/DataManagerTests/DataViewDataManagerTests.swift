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

@MainActor
struct DataViewDataManagerTests {

  // Each test gets its own in-memory database, nothing is shared
  let realm: Realm
  let manager: DataViewDataManager
  let hostId = UUID()

  init() throws {
    let realm = try Realm(configuration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                                                             schemaVersion: RealmManager.schemaVersion))
    self.realm = realm
    self.manager = DataViewDataManager(realmProvider: { realm })
  }

  private func draft(_ name: String, pattern: String = "logs-*", host: UUID? = nil) -> DataView {
    DataView(hostId: host ?? hostId, name: name, pattern: pattern)
  }

  // MARK: - Create

  @Test func createStoresATrimmedView() throws {
    var view = draft("  Experiments  ", pattern: " backtesting-experiments-* ")
    view.timeField = "@timestamp"
    view.labels = ["durationSeconds": " Duration (s) ", "RUN_ID": "   ", "": "Nothing"]

    let created = try manager.create(view)

    let stored = try #require(manager.view(id: created.id))
    #expect(stored.name == "Experiments")
    #expect(stored.pattern == "backtesting-experiments-*")
    #expect(stored.timeField == "@timestamp")
    #expect(stored.labels == ["durationSeconds": "Duration (s)"])
    #expect(stored.hostId == hostId)
  }

  @Test func createRemovesSpacesAroundCommas() throws {
    let created = try manager.create(draft("Logs and metrics", pattern: " logs-* , metrics-* "))
    #expect(created.pattern == "logs-*,metrics-*")
    #expect(throws: (any Error).self) { try manager.create(draft("Gap", pattern: "logs-*, ,metrics-*")) }
  }

  @Test func createRejectsInvalidViews() {
    #expect(throws: DataViewError.nameEmpty) { try manager.create(draft("  ")) }
    #expect(throws: DataViewError.patternEmpty) { try manager.create(draft("Logs", pattern: "")) }
    #expect(throws: (any Error).self) { try manager.create(draft("Logs", pattern: "logs?")) }
    #expect(realm.objects(RealmDataView.self).isEmpty)
  }

  @Test func namesAreUniquePerHostIgnoringCase() throws {
    try manager.create(draft("Logs"))

    #expect(throws: DataViewError.nameTaken) { try manager.create(draft("logs ")) }
    // Another host may reuse the name, and the same pattern is fine on the same host
    try manager.create(draft("Logs", host: UUID()))
    try manager.create(draft("Other logs", pattern: "logs-*"))

    #expect(realm.objects(RealmDataView.self).count == 3)
  }

  // MARK: - Read

  @Test func viewsAreForOneHostSortedByName() throws {
    try manager.create(draft("zeta"))
    try manager.create(draft("Alpha"))
    try manager.create(draft("beta"))
    try manager.create(draft("Elsewhere", host: UUID()))

    #expect(manager.views(hostId: hostId).map(\.name) == ["Alpha", "beta", "zeta"])
  }

  // MARK: - Update

  @Test func updateReplacesFieldsAndLabels() throws {
    var view = draft("Logs")
    view.labels = ["a": "A", "b": "B"]
    var created = try manager.create(view)

    created.name = "App logs"
    created.pattern = "app-logs-*"
    created.timeField = "event.created"
    created.labels = ["b": "Bee", "c": "C"]
    try manager.update(created)

    let stored = try #require(manager.view(id: created.id))
    #expect(stored.name == "App logs")
    #expect(stored.pattern == "app-logs-*")
    #expect(stored.timeField == "event.created")
    #expect(stored.labels == ["b": "Bee", "c": "C"])
    #expect(stored.createdDate == created.createdDate)
    #expect(stored.updatedDate >= created.updatedDate)
  }

  @Test func updateKeepsItsOwnNameButNotAnother() throws {
    var first = try manager.create(draft("First"))
    try manager.create(draft("Second"))

    first.pattern = "first-*"
    try manager.update(first)

    first.name = "SECOND"
    #expect(throws: DataViewError.nameTaken) { try manager.update(first) }
    #expect(manager.view(id: first.id)?.name == "First")
  }

  @Test func updateOfADeletedViewFails() throws {
    let created = try manager.create(draft("Logs"))
    manager.delete(id: created.id)

    #expect(throws: DataViewError.notFound) { try manager.update(created) }
  }

  // MARK: - Delete

  @Test func deleteRemovesOnlyThatView() throws {
    let created = try manager.create(draft("Logs"))
    let other = try manager.create(draft("Other"))

    manager.delete(id: created.id)

    #expect(manager.view(id: created.id) == nil)
    #expect(manager.view(id: other.id) != nil)
  }

  @Test func deleteByHostOnlyTouchesThatHost() throws {
    let otherHost = UUID()
    try manager.create(draft("One"))
    try manager.create(draft("Two"))
    try manager.create(draft("Kept", host: otherHost))

    manager.deleteByHost(id: hostId)

    #expect(manager.views(hostId: hostId).isEmpty)
    #expect(manager.views(hostId: otherHost).map(\.name) == ["Kept"])
  }

  @Test func pruneOrphansRemovesViewsForMissingHosts() throws {
    let goneHost = UUID()
    try manager.create(draft("Kept"))
    try manager.create(draft("Gone 1", host: goneHost))
    try manager.create(draft("Gone 2", host: goneHost))

    #expect(manager.pruneOrphans(validHostIds: [hostId]) == 2)
    #expect(manager.views(hostId: hostId).map(\.name) == ["Kept"])
    #expect(manager.views(hostId: goneHost).isEmpty)
    #expect(manager.pruneOrphans(validHostIds: [hostId]) == 0)
  }

  // MARK: - Changes

  @Test func hasChangesIgnoresWhitespaceAndEmptyLabels() {
    let base = DataView(hostId: hostId, name: "Logs", pattern: "logs-*", labels: ["a": "A"])
    var same = base
    same.name = " Logs "
    same.labels = ["a": "A ", "b": ""]
    #expect(!same.hasChanges(comparedTo: base))

    var changed = base
    changed.labels["b"] = "B"
    #expect(changed.hasChanges(comparedTo: base))
  }
}
