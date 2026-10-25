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
  // Only read for panels saved before the grid, to lay them out as they were. 0 reads as 2.
  @Persisted public var columns: Int = 2
  // Embedded, so deleting the dashboard deletes its panels
  @Persisted public var panels: List<RealmDashboardPanel>
  @Persisted public var refreshSeconds: Int = 0
  @Persisted public var createdDate: Date = Date.now
  @Persisted public var updatedDate: Date?

  public convenience init(dashboard: Dashboard) {
    self.init()
    self.id = dashboard.id
    self.title = dashboard.title
    self.panels.append(objectsIn: dashboard.panels.map(RealmDashboardPanel.init))
    self.refreshSeconds = dashboard.refreshSeconds
    self.createdDate = dashboard.createdDate
    self.updatedDate = dashboard.updatedDate
  }

  /// A plain copy that's safe to keep after the object is deleted. Panels saved before the grid are laid out as they
  /// were, and gaps left by panels removed are closed.
  public func eject() -> Dashboard {
    let stored = Array(panels)
    let laidOut = stored.filter { $0.w > 0 }
    let unplaced = stored.filter { $0.w == 0 }
    var frames = DashboardLayout.Frames()
    if laidOut.isEmpty {
      frames = DashboardLayout.legacyFrames(unplaced.map { $0.legacyPanel }, columns: columns)
    } else {
      for panel in laidOut {
        frames[panel.id] = panel.frame
      }
      for panel in unplaced {
        frames[panel.id] = DashboardLayout.insertionFrame(frames)
      }
    }
    frames = DashboardLayout.compact(frames)
    return Dashboard(id: id,
                     title: title,
                     panels: stored.compactMap { panel in
                       frames[panel.id].map { DashboardPanel(id: panel.id,
                                                             savedSearchId: panel.savedSearchId,
                                                             frame: $0,
                                                             columnWidths: panel.widths) }
                     },
                     refreshSeconds: refreshSeconds,
                     createdDate: createdDate,
                     updatedDate: updatedDate)
  }

  /// Saves where each panel sits. Panels not in `frames` keep theirs.
  public func store(_ frames: DashboardLayout.Frames) {
    for panel in panels {
      if let frame = frames[panel.id] {
        panel.frame = frame
      }
    }
  }
}

/// A saved search placed on a dashboard
public class RealmDashboardPanel: EmbeddedObject {
  @Persisted public var id: UUID
  @Persisted public var savedSearchId: UUID
  // The size before the grid: "single" or "full", and "small", "medium" or "large". Only read while w is 0.
  @Persisted public var width: String = ""
  @Persisted public var height: String = ""
  // Its grid frame. A width of 0 means it was saved before the grid.
  @Persisted public var x: Int = 0
  @Persisted public var y: Int = 0
  @Persisted public var w: Int = 0
  @Persisted public var h: Int = 0
  // Column widths set on the dashboard. Empty uses the saved search's.
  @Persisted public var columnWidths: List<RealmColumnWidth>

  public convenience init(panel: DashboardPanel) {
    self.init()
    self.id = panel.id
    self.savedSearchId = panel.savedSearchId
    self.frame = panel.frame
    self.widths = panel.columnWidths
  }

  public var widths: [String: Double] {
    get { Dictionary(columnWidths.map { ($0.column, $0.width) }, uniquingKeysWith: { first, _ in first }) }
    set {
      columnWidths.removeAll()
      columnWidths.append(objectsIn: RealmColumnWidth.list(newValue))
    }
  }

  public var frame: DashboardGridFrame {
    get { DashboardGridFrame(x: x, y: y, w: w, h: h).clamped }
    set {
      let frame = newValue.clamped
      x = frame.x
      y = frame.y
      w = frame.w
      h = frame.h
    }
  }

  var legacyPanel: DashboardLayout.LegacyPanel {
    let documents: Int
    switch height {
    case "small": documents = 5
    case "large": documents = 20
    default: documents = 10
    }
    return DashboardLayout.LegacyPanel(id: id, fullWidth: width == "full", documents: documents)
  }
}
