// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// A saved search placed on a dashboard
public struct DashboardPanel: Identifiable, Equatable, Hashable {
  public var id: UUID
  /// The saved search shown. Panels follow it, so updating the search updates the panel.
  public var savedSearchId: UUID
  /// Where it sits on the dashboard's grid
  public var frame: DashboardGridFrame
  /// Column widths set by dragging a border on the dashboard, by `DashboardColumn.savedKey`. They win over the
  /// saved search's own, which they never change.
  public var columnWidths: [String: Double]

  public init(id: UUID = UUID(),
              savedSearchId: UUID,
              frame: DashboardGridFrame = DashboardGridFrame(x: 0, y: 0,
                                                             w: DashboardLayout.defaultWidth,
                                                             h: DashboardLayout.defaultHeight),
              columnWidths: [String: Double] = [:]) {
    self.id = id
    self.savedSearchId = savedSearchId
    self.frame = frame
    self.columnWidths = columnWidths
  }

  /// The documents the panel searches for and shows, as many as fit its height
  public var rowLimit: Int {
    DashboardLayout.rowLimit(height: frame.h)
  }
}

/// A named grid of saved searches, shown side by side in the Dashboards tab
public struct Dashboard: Identifiable, Equatable, Hashable {
  /// Auto refresh choices in seconds. 0 is off.
  public static let refreshIntervals = [0, 30, 60, 300, 900]

  public var id: UUID
  public var title: String
  /// Panels in reading order: top to bottom, then left to right
  public var panels: [DashboardPanel]
  /// How often every panel searches again, in seconds. 0 is off.
  public var refreshSeconds: Int
  public var createdDate: Date
  /// When its panels or layout last changed, nil if never
  public var updatedDate: Date?

  public init(id: UUID = UUID(),
              title: String,
              panels: [DashboardPanel] = [],
              refreshSeconds: Int = 0,
              createdDate: Date = Date.now,
              updatedDate: Date? = nil) {
    self.id = id
    self.title = title
    self.panels = Self.readingOrder(panels)
    self.refreshSeconds = max(0, refreshSeconds)
    self.createdDate = createdDate
    self.updatedDate = updatedDate
  }

  /// Each panel's place on the grid, by panel id
  public var frames: DashboardLayout.Frames {
    Dictionary(panels.map { ($0.id, $0.frame) }, uniquingKeysWith: { first, _ in first })
  }

  /// The dashboard with its panels moved to `frames`. Panels left out stay where they are.
  public func with(frames: DashboardLayout.Frames) -> Dashboard {
    var copy = self
    copy.panels = Self.readingOrder(panels.map { panel in
      var moved = panel
      moved.frame = frames[panel.id] ?? panel.frame
      return moved
    })
    return copy
  }

  /// The ids of the saved searches shown, once each, in reading order
  public var savedSearchIds: [UUID] {
    var seen = Set<UUID>()
    return panels.map(\.savedSearchId).filter { seen.insert($0).inserted }
  }

  /// A name for a new dashboard that isn't taken: "Dashboard", then "Dashboard 2", "Dashboard 3"...
  public static func newTitle(existing: [String]) -> String {
    let taken = Set(existing.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
    let base = "Dashboard"
    if !taken.contains(base.lowercased()) {
      return base
    }
    var number = 2
    while taken.contains("\(base) \(number)".lowercased()) {
      number += 1
    }
    return "\(base) \(number)"
  }

  /// Top to bottom, then left to right
  static func readingOrder(_ panels: [DashboardPanel]) -> [DashboardPanel] {
    panels.sorted { lhs, rhs in
      (lhs.frame.y, lhs.frame.x, lhs.id.uuidString) < (rhs.frame.y, rhs.frame.x, rhs.id.uuidString)
    }
  }

  /// "Off", "30 seconds", "1 minute", "5 minutes"...
  public static func refreshTitle(_ seconds: Int) -> String {
    if seconds <= 0 {
      return "Off"
    }
    if seconds < 60 {
      return "\(seconds) seconds"
    }
    let minutes = seconds / 60
    return minutes == 1 ? "1 minute" : "\(minutes) minutes"
  }

  /// "Off", "30s", "1m", "5m"...
  public static func shortRefreshTitle(_ seconds: Int) -> String {
    if seconds <= 0 {
      return "Off"
    }
    return seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m"
  }
}
