// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// A dashboard and its panels.
/// New columns must be optional or default to a valid empty value, and not be enums:
/// rows that already exist start with the column empty, so no migration code is needed.
public class RealmDashboard: Object {

  @Persisted(primaryKey: true) public var id: UUID
  @Persisted public var title: String = ""
  // 0 reads as the default
  @Persisted public var columns: Int = Dashboard.defaultColumns
  // Embedded, so deleting the dashboard deletes its panels. List order is grid order.
  @Persisted public var panels: List<RealmDashboardPanel>
  @Persisted public var refreshSeconds: Int = 0
  @Persisted public var createdDate: Date = Date.now
  @Persisted public var updatedDate: Date?

  public convenience init(dashboard: Dashboard) {
    self.init()
    self.id = dashboard.id
    self.title = dashboard.title
    self.columns = dashboard.columns
    self.panels.append(objectsIn: dashboard.panels.map(RealmDashboardPanel.init))
    self.refreshSeconds = dashboard.refreshSeconds
    self.createdDate = dashboard.createdDate
    self.updatedDate = dashboard.updatedDate
  }

  /// A plain copy that's safe to keep after the object is deleted
  public func eject() -> Dashboard {
    Dashboard(id: id,
              title: title,
              columns: columns == 0 ? Dashboard.defaultColumns : columns,
              panels: panels.map { $0.eject() },
              refreshSeconds: refreshSeconds,
              createdDate: createdDate,
              updatedDate: updatedDate)
  }
}

/// A saved search placed on a dashboard
public class RealmDashboardPanel: EmbeddedObject {
  @Persisted public var id: UUID
  @Persisted public var savedSearchId: UUID
  // DashboardPanelWidth and DashboardPanelHeight raw values, kept as strings so an empty column reads as the default
  @Persisted public var width: String = ""
  @Persisted public var height: String = ""

  public convenience init(panel: DashboardPanel) {
    self.init()
    self.id = panel.id
    self.savedSearchId = panel.savedSearchId
    self.width = panel.width.rawValue
    self.height = panel.height.rawValue
  }

  public func eject() -> DashboardPanel {
    DashboardPanel(id: id,
                   savedSearchId: savedSearchId,
                   width: DashboardPanelWidth(rawValue: width) ?? .single,
                   height: DashboardPanelHeight(rawValue: height) ?? .medium)
  }
}
