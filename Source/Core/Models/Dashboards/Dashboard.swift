// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// How much of a dashboard row a panel takes
public enum DashboardPanelWidth: String, CaseIterable {
  /// One column of the grid
  case single = "single"
  /// The whole row, whatever the number of columns
  case full = "full"

  public var title: String {
    switch self {
    case .single: return "One column"
    case .full: return "Full width"
    }
  }
}

/// How tall a panel is, which is also how many documents it searches for
public enum DashboardPanelHeight: String, CaseIterable {
  case small = "small"
  case medium = "medium"
  case large = "large"

  public var title: String {
    switch self {
    case .small: return "Small"
    case .medium: return "Medium"
    case .large: return "Large"
    }
  }

  /// The documents the panel searches for and shows
  public var rowLimit: Int {
    switch self {
    case .small: return 5
    case .medium: return 10
    case .large: return 20
    }
  }
}

/// A saved search placed on a dashboard
public struct DashboardPanel: Identifiable, Equatable, Hashable {
  public var id: UUID
  /// The saved search shown. Panels follow it, so updating the search updates the panel.
  public var savedSearchId: UUID
  public var width: DashboardPanelWidth
  public var height: DashboardPanelHeight

  public init(id: UUID = UUID(),
              savedSearchId: UUID,
              width: DashboardPanelWidth = .single,
              height: DashboardPanelHeight = .medium) {
    self.id = id
    self.savedSearchId = savedSearchId
    self.width = width
    self.height = height
  }
}

/// A named grid of saved searches, shown side by side in the Dashboards tab
public struct Dashboard: Identifiable, Equatable, Hashable {
  public static let columnRange = 1...3
  public static let defaultColumns = 2
  /// Auto refresh choices in seconds. 0 is off.
  public static let refreshIntervals = [0, 30, 60, 300, 900]

  public var id: UUID
  public var title: String
  /// Columns in the grid, within `columnRange`
  public var columns: Int
  /// Panels in grid order
  public var panels: [DashboardPanel]
  /// How often every panel searches again, in seconds. 0 is off.
  public var refreshSeconds: Int
  public var createdDate: Date
  /// When its panels or layout last changed, nil if never
  public var updatedDate: Date?

  public init(id: UUID = UUID(),
              title: String,
              columns: Int = Dashboard.defaultColumns,
              panels: [DashboardPanel] = [],
              refreshSeconds: Int = 0,
              createdDate: Date = Date.now,
              updatedDate: Date? = nil) {
    self.id = id
    self.title = title
    self.columns = Dashboard.clampedColumns(columns)
    self.panels = panels
    self.refreshSeconds = max(0, refreshSeconds)
    self.createdDate = createdDate
    self.updatedDate = updatedDate
  }

  public static func clampedColumns(_ columns: Int) -> Int {
    min(max(columns, columnRange.lowerBound), columnRange.upperBound)
  }

  /// The ids of the saved searches shown, once each, in grid order
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

  /// Panel ids in their new order after dragging `moving` onto `target`: it takes the target's place, and the
  /// panels in between shift along by one. Unchanged when either isn't in `ids`.
  public static func reordered(_ ids: [UUID], moving: UUID, onto target: UUID) -> [UUID] {
    guard moving != target,
          let from = ids.firstIndex(of: moving),
          let to = ids.firstIndex(of: target) else { return ids }
    var result = ids
    result.remove(at: from)
    result.insert(moving, at: to)
    return result
  }

  /// The panels as grid rows, in order: one-column panels fill rows of `columns`, and a full width panel takes a
  /// row of its own, ending any row it interrupts early.
  public static func rows(_ panels: [DashboardPanel], columns: Int) -> [[DashboardPanel]] {
    let columns = clampedColumns(columns)
    var rows = [[DashboardPanel]]()
    var current = [DashboardPanel]()
    for panel in panels {
      if panel.width == .full {
        if !current.isEmpty {
          rows.append(current)
          current = []
        }
        rows.append([panel])
      } else {
        current.append(panel)
        if current.count == columns {
          rows.append(current)
          current = []
        }
      }
    }
    if !current.isEmpty {
      rows.append(current)
    }
    return rows
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
}
