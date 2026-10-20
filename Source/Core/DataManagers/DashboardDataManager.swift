// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// Reads and writes dashboards. Callers only ever get `Dashboard` values, never live Realm objects.
@MainActor
public class DashboardDataManager {

  private let realmProvider: @MainActor () -> Realm?

  public init(realmProvider: @escaping @MainActor () -> Realm? = { RealmManager().getRealm() }) {
    self.realmProvider = realmProvider
  }

  // MARK: - Reading

  /// Every dashboard, oldest first, so new ones are added at the end of the list
  public func all() -> [Dashboard] {
    guard let realm = realmProvider() else { return [] }
    return realm.objects(RealmDashboard.self)
      .sorted(byKeyPath: "createdDate", ascending: true)
      .map { $0.eject() }
  }

  public func dashboard(id: UUID) -> Dashboard? {
    guard let realm = realmProvider() else { return nil }
    return realm.object(ofType: RealmDashboard.self, forPrimaryKey: id)?.eject()
  }

  // MARK: - Dashboards

  /// Adds an empty dashboard. An empty title takes the next free "Dashboard" name.
  @discardableResult
  public func create(title: String = "", now: Date = Date.now) throws -> Dashboard {
    guard let realm = realmProvider() else { throw SavedDocumentError.storageUnavailable }
    var trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      trimmed = Dashboard.newTitle(existing: realm.objects(RealmDashboard.self).map(\.title))
    }
    let object = RealmDashboard(dashboard: Dashboard(title: trimmed, createdDate: now))
    try realm.write {
      realm.add(object)
    }
    return object.eject()
  }

  /// Changes the title. An empty title keeps the old one, a dashboard always has a name.
  @discardableResult
  public func rename(id: UUID, title: String) throws -> Dashboard {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    return try change(id: id, touch: false) { object in
      if !trimmed.isEmpty {
        object.title = trimmed
      }
    }
  }

  public func delete(id: UUID) {
    guard let realm = realmProvider(),
          let object = realm.object(ofType: RealmDashboard.self, forPrimaryKey: id) else { return }
    try? realm.write {
      realm.delete(object)
    }
  }

  @discardableResult
  public func setColumns(id: UUID, columns: Int) throws -> Dashboard {
    try change(id: id) { $0.columns = Dashboard.clampedColumns(columns) }
  }

  @discardableResult
  public func setRefreshInterval(id: UUID, seconds: Int) throws -> Dashboard {
    try change(id: id) { $0.refreshSeconds = max(0, seconds) }
  }

  // MARK: - Panels

  /// Adds a panel at the end for each saved search, skipping searches the dashboard already shows
  @discardableResult
  public func addPanels(id: UUID, savedSearchIds: [UUID]) throws -> Dashboard {
    try change(id: id) { object in
      var shown = Set(object.panels.map(\.savedSearchId))
      for searchId in savedSearchIds where shown.insert(searchId).inserted {
        object.panels.append(RealmDashboardPanel(panel: DashboardPanel(savedSearchId: searchId)))
      }
    }
  }

  @discardableResult
  public func removePanel(id: UUID, panelId: UUID) throws -> Dashboard {
    try change(id: id) { object in
      if let index = object.panels.firstIndex(where: { $0.id == panelId }) {
        object.panels.remove(at: index)
      }
    }
  }

  /// Puts the panels in the order of `panelIds`. Panels left out keep their order after the ones given.
  @discardableResult
  public func setPanelOrder(id: UUID, panelIds: [UUID]) throws -> Dashboard {
    try change(id: id) { object in
      let current = Array(object.panels.map { $0.eject() })
      let position = Dictionary(panelIds.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
      let ordered = current.enumerated().sorted { lhs, rhs in
        let left = position[lhs.element.id] ?? panelIds.count + lhs.offset
        let right = position[rhs.element.id] ?? panelIds.count + rhs.offset
        return left < right
      }.map(\.element)
      guard ordered != current else { return }
      object.panels.removeAll()
      object.panels.append(objectsIn: ordered.map(RealmDashboardPanel.init))
    }
  }

  @discardableResult
  public func setPanelSize(id: UUID,
                           panelId: UUID,
                           width: DashboardPanelWidth,
                           height: DashboardPanelHeight) throws -> Dashboard {
    try change(id: id) { object in
      guard let panel = object.panels.first(where: { $0.id == panelId }) else { return }
      panel.width = width.rawValue
      panel.height = height.rawValue
    }
  }

  // MARK: - Removing saved searches

  /// Removes the panels showing saved searches that no longer exist. Returns how many were removed.
  @discardableResult
  public func pruneMissingSearches(validSearchIds: Set<UUID>) -> Int {
    guard let realm = realmProvider() else { return 0 }
    var count = 0
    try? realm.write {
      count = Self.removePanels(in: realm) { !validSearchIds.contains($0) }
    }
    return count
  }

  /// Removes every panel whose saved search matches. Call inside a write, eg. the one deleting the saved searches,
  /// so a dashboard never points at a search that's gone.
  @discardableResult
  static func removePanels(in realm: Realm, where matches: (UUID) -> Bool) -> Int {
    var count = 0
    for dashboard in realm.objects(RealmDashboard.self) {
      let indices = dashboard.panels.indices.filter { matches(dashboard.panels[$0].savedSearchId) }
      // From the end, so the indices still to remove don't move
      for index in indices.reversed() {
        dashboard.panels.remove(at: index)
      }
      count += indices.count
    }
    return count
  }

  // MARK: - Helpers

  /// Applies `update` to the dashboard in one write and returns it as it then is. `touch` marks it as updated.
  private func change(id: UUID, touch: Bool = true, _ update: (RealmDashboard) -> Void) throws -> Dashboard {
    guard let realm = realmProvider() else { throw SavedDocumentError.storageUnavailable }
    guard let object = realm.object(ofType: RealmDashboard.self, forPrimaryKey: id) else {
      throw SavedDocumentError.notFound
    }
    try realm.write {
      update(object)
      if touch {
        object.updatedDate = Date.now
      }
    }
    return object.eject()
  }
}
