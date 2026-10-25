// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

extension DashboardColumn {
  /// How saved searches and panels key the column's width, the same as the Search tab: eg. "field:status"
  public var savedKey: String {
    switch self {
    case .date(let key): return "date:\(key)"
    case .field(let key): return "field:\(key)"
    case .document: return "document"
    }
  }
}

/// How wide each column of a dashboard panel's table is drawn. Sized like the Search tab's table: a width set on the
/// panel wins, then one saved with the search, then one fitted to the header and the documents shown. The last
/// column takes whatever room is left, and when there isn't enough, columns give some back.
public enum DashboardColumnWidths {
  /// The Search tab's limits for automatic widths
  public static let minWidth: Double = 60
  public static let maxWidth: Double = 300
  /// Horizontal padding inside a cell, plus a little slack for rounding
  public static let cellPadding: Double = 22
  /// A column dragged narrower than its name still has room for "…"
  public static let minSetWidth: Double = 30
  public static let maxSetWidth: Double = 2000
  /// Automatic widths stop at `maxWidth`, so long values are only measured this far
  public static let measureLength = 120

  /// Each column fitted to its header and widest cell, within `minWidth` and `maxWidth`. `measure` gives a text's
  /// width, bold for headers.
  public static func automatic(columns: [DashboardColumn],
                               rows: [DashboardRow],
                               measure: (_ text: String, _ bold: Bool) -> Double) -> [DashboardColumn: Double] {
    var widths = [DashboardColumn: Double]()
    for (index, column) in columns.enumerated() {
      var widest = measure(column.title, true)
      for row in rows where index < row.cells.count {
        if let text = row.cells[index] {
          widest = max(widest, measure(String(text.prefix(measureLength)), false))
        }
      }
      widths[column] = min(max(widest + cellPadding, minWidth), maxWidth)
    }
    return widths
  }

  /// Each column fitted to its whole header and documents, for a double-click on a border. Unlike the automatic
  /// widths these go past `maxWidth`, up to `maxSetWidth`. Keyed by `savedKey`, ready to save on the panel.
  public static func fittedToContents(columns: [DashboardColumn],
                                      rows: [DashboardRow],
                                      measure: (_ text: String, _ bold: Bool) -> Double) -> [String: Double] {
    var widths = [String: Double]()
    for (index, column) in columns.enumerated() {
      var widest = measure(column.title, true)
      for row in rows where index < row.cells.count {
        if let text = row.cells[index] {
          widest = max(widest, measure(String(text.prefix(fittedMeasureLength)), false))
        }
      }
      widths[column.savedKey] = clampedSetWidth(widest + cellPadding)
    }
    return widths
  }

  /// More characters than this are wider than `maxSetWidth` even in the narrowest letters
  public static let fittedMeasureLength = 1000

  /// The width each column would like, and which of them were set by someone rather than fitted. Set widths are
  /// keyed by `savedKey`: `panel` from dragging on the dashboard, `search` from dragging in the Search tab.
  public static func preferred(columns: [DashboardColumn],
                               automatic: [DashboardColumn: Double],
                               search: [String: Double],
                               panel: [String: Double]) -> (widths: [DashboardColumn: Double], set: Set<DashboardColumn>) {
    var widths = [DashboardColumn: Double]()
    var set = Set<DashboardColumn>()
    for column in columns {
      if let width = panel[column.savedKey] ?? search[column.savedKey], width > 0 {
        widths[column] = clampedSetWidth(width)
        set.insert(column)
      } else {
        widths[column] = automatic[column] ?? minWidth
      }
    }
    return (widths, set)
  }

  public static func clampedSetWidth(_ width: Double) -> Double {
    min(max(width, minSetWidth), maxSetWidth)
  }

  /// The widths to draw `columns` at in a table `available` points wide. The last column fills the rest of the row.
  /// When the others leave it less than `minWidth`, the fitted columns shrink first, evenly by how much they're
  /// over `minWidth`, then the set ones down to `minSetWidth`. Anything still too wide is cut off.
  public static func fitted(columns: [DashboardColumn],
                            preferred: [DashboardColumn: Double],
                            set: Set<DashboardColumn>,
                            available: Double) -> [Double] {
    guard let last = columns.last else { return [] }
    var widths = columns.dropLast().map { preferred[$0] ?? minWidth }
    let others = Array(columns.dropLast())
    func excess() -> Double {
      widths.reduce(0, +) + minWidth - available
    }
    // Fitted columns first, then the ones someone sized
    for (isSet, floor) in [(false, minWidth), (true, minSetWidth)] where excess() > 0 {
      let shrinkable = others.indices.filter { set.contains(others[$0]) == isSet }
      let room = shrinkable.reduce(0) { $0 + max(widths[$1] - floor, 0) }
      guard room > 0 else { continue }
      let share = min(excess() / room, 1)
      for index in shrinkable {
        // Whole points; the last column takes up the rounding
        widths[index] = (widths[index] - max(widths[index] - floor, 0) * share).rounded()
      }
    }
    let lastWidth = max(available - widths.reduce(0, +), min(preferred[last] ?? minWidth, minWidth))
    return widths + [lastWidth]
  }
}
