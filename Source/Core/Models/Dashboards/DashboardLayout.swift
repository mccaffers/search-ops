// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// Where a panel sits on a dashboard, in grid cells: `x` and `w` in columns of `DashboardLayout.columns`, `y` and
/// `h` in rows of `DashboardLayout.rowHeight`
public struct DashboardGridFrame: Equatable, Hashable {
  public var x: Int
  public var y: Int
  public var w: Int
  public var h: Int

  public init(x: Int, y: Int, w: Int, h: Int) {
    self.x = x
    self.y = y
    self.w = w
    self.h = h
  }

  public var maxX: Int { x + w }
  public var maxY: Int { y + h }

  public func overlaps(_ other: DashboardGridFrame) -> Bool {
    x < other.maxX && other.x < maxX && y < other.maxY && other.y < maxY
  }

  /// Within the grid's columns and no smaller than the smallest panel
  public var clamped: DashboardGridFrame {
    let w = min(max(self.w, DashboardLayout.minWidth), DashboardLayout.columns)
    let h = min(max(self.h, DashboardLayout.minHeight), DashboardLayout.maxHeight)
    return DashboardGridFrame(x: min(max(x, 0), DashboardLayout.columns - w), y: max(y, 0), w: w, h: h)
  }
}

/// Arranges dashboard panels on a grid of 12 columns. Panels never overlap, and they rise to fill any gap above
/// them, so moving, resizing or removing one makes the others close up around it.
public enum DashboardLayout {
  public static let columns = 12
  public static let minWidth = 2
  public static let minHeight = 3
  public static let maxHeight = 40
  public static let defaultWidth = 6
  public static let defaultHeight = 7

  /// The height of one grid row, and the space between panels, in points
  public static let rowHeight: Double = 40
  public static let spacing: Double = 10
  /// A panel's title, footer and padding, and its table's header and row heights, as drawn by the macOS panel view
  public static let panelChromeHeight: Double = 86
  public static let tableHeaderHeight: Double = 24
  public static let tableRowHeight: Double = 22
  public static let maxRowLimit = 100

  public typealias Frames = [UUID: DashboardGridFrame]

  // MARK: - Sizes

  /// The height in points of a panel `h` rows tall, the gaps between its rows included
  public static func height(rows h: Int) -> Double {
    Double(h) * rowHeight + Double(max(h - 1, 0)) * spacing
  }

  /// How many documents fit in a panel `h` rows tall, which is how many it searches for
  public static func rowLimit(height h: Int) -> Int {
    let space = height(rows: h) - panelChromeHeight - tableHeaderHeight
    return min(max(Int(space / tableRowHeight), 1), maxRowLimit)
  }

  /// The lowest panel height that shows at least `documents` documents
  public static func height(fitting documents: Int) -> Int {
    var h = minHeight
    while h < maxHeight && rowLimit(height: h) < documents {
      h += 1
    }
    return h
  }

  /// The number of grid rows the panels take
  public static func bottom(_ frames: Frames) -> Int {
    frames.values.map(\.maxY).max() ?? 0
  }

  /// Width choices in a panel's menu, in columns
  public static let widthPresets: [(title: String, w: Int)] = [("Quarter", 3), ("Third", 4), ("Half", 6),
                                                                ("Two thirds", 8), ("Full width", 12)]
  /// Height choices in a panel's menu, by the documents they show
  public static let heightPresets: [(title: String, documents: Int)] = [("Small", 5), ("Medium", 10), ("Large", 20)]

  // MARK: - Dashboards saved before the grid

  /// A panel as dashboards before the grid kept it: one column or the full width, and the documents it showed
  public struct LegacyPanel {
    public var id: UUID
    public var fullWidth: Bool
    public var documents: Int

    public init(id: UUID, fullWidth: Bool, documents: Int) {
      self.id = id
      self.fullWidth = fullWidth
      self.documents = documents
    }
  }

  /// The grid frames that look like the old layout: rows of `columns` equal panels, in order, and full width panels
  /// on rows of their own, ending any row they interrupt early
  public static func legacyFrames(_ panels: [LegacyPanel], columns: Int) -> Frames {
    let columnCount = min(max(columns == 0 ? 2 : columns, 1), 3)
    let width = Self.columns / columnCount
    var frames = Frames()
    var x = 0
    var y = 0
    var rowHeight = 0
    func endRow() {
      y += rowHeight
      x = 0
      rowHeight = 0
    }
    for panel in panels {
      let w = panel.fullWidth ? Self.columns : width
      if x + w > Self.columns {
        endRow()
      }
      let h = height(fitting: panel.documents)
      frames[panel.id] = DashboardGridFrame(x: x, y: y, w: w, h: h)
      rowHeight = max(rowHeight, h)
      x += w
      if x >= Self.columns {
        endRow()
      }
    }
    return compact(frames)
  }

  // MARK: - Changes

  /// Every panel within the grid, overlaps pushed apart and gaps closed. Where two panels start in the same cell,
  /// the `preferring` one stays and the other goes below it.
  public static func compact(_ frames: Frames, preferring: Set<UUID> = []) -> Frames {
    arrange(frames.mapValues(\.clamped), fixed: nil, preferring: preferring)
  }

  /// `id` moved to `target`: panels in the way swap into the space it left, go above it, or go below it, then
  /// everything rises to close the gaps
  public static func move(_ frames: Frames, id: UUID, to target: DashboardGridFrame) -> Frames {
    guard let current = frames[id] else { return frames }
    var moved = frames
    moved[id] = DashboardGridFrame(x: target.x, y: target.y, w: current.w, h: current.h).clamped
    return compact(arrange(moved, fixed: (id: id, vacated: current)))
  }

  /// `id` resized to `size`, keeping its top left corner: panels in the way go below it, then everything rises to
  /// close the gaps
  public static func resize(_ frames: Frames, id: UUID, to size: DashboardGridFrame) -> Frames {
    guard let current = frames[id] else { return frames }
    var resized = frames
    resized[id] = DashboardGridFrame(x: current.x, y: current.y, w: size.w, h: size.h).clamped
    return compact(arrange(resized, fixed: (id: id, vacated: nil)))
  }

  /// Where a new panel `w` by `h` goes: the first gap it fits, row by row from the top, or else below the rest
  public static func insertionFrame(_ frames: Frames, w: Int = defaultWidth, h: Int = defaultHeight) -> DashboardGridFrame {
    let size = DashboardGridFrame(x: 0, y: 0, w: w, h: h).clamped
    let others = Array(frames.values)
    for y in 0...bottom(frames) {
      for x in 0...(columns - size.w) {
        let frame = DashboardGridFrame(x: x, y: y, w: size.w, h: size.h)
        if !others.contains(where: frame.overlaps) {
          return frame
        }
      }
    }
    return DashboardGridFrame(x: 0, y: bottom(frames), w: size.w, h: size.h)
  }

  /// The panels without `id`, risen to fill the space it took
  public static func remove(_ frames: Frames, id: UUID) -> Frames {
    var remaining = frames
    remaining[id] = nil
    return compact(remaining)
  }

  // MARK: - Helpers

  /// Places every panel, top to bottom, so none overlap. The `fixed` panel stays exactly where it is and the others
  /// make way for it; with no fixed panel, each one rises as far as it can.
  private static func arrange(_ frames: Frames,
                              fixed: (id: UUID, vacated: DashboardGridFrame?)?,
                              preferring: Set<UUID> = []) -> Frames {
    var placed = Frames()
    var fixedFrame: DashboardGridFrame? = nil
    if let fixed = fixed, let frame = frames[fixed.id] {
      placed[fixed.id] = frame
      fixedFrame = frame
    }
    // Top to bottom, then left to right, the id settling ties so the result never depends on dictionary order
    let order = frames.keys
      .filter { $0 != fixed?.id }
      .sorted { lhs, rhs in
        let a = frames[lhs]!, b = frames[rhs]!
        let aRank = preferring.contains(lhs) ? 0 : 1, bRank = preferring.contains(rhs) ? 0 : 1
        return (a.y, a.x, aRank, lhs.uuidString) < (b.y, b.x, bRank, rhs.uuidString)
      }
    for id in order {
      var frame = frames[id]!
      func isFree(_ candidate: DashboardGridFrame) -> Bool {
        candidate.y >= 0 && !placed.values.contains(where: candidate.overlaps)
      }
      if !isFree(frame) {
        if let fixedFrame = fixedFrame, frame.overlaps(fixedFrame),
           let swapped = makeWay(for: frame, around: fixedFrame, vacated: fixed?.vacated, isFree: isFree) {
          frame = swapped
        } else {
          // Below whatever it's in the way of
          while !isFree(frame) {
            frame.y += 1
          }
        }
      }
      // Rises as far as it can
      while isFree(DashboardGridFrame(x: frame.x, y: frame.y - 1, w: frame.w, h: frame.h)) {
        frame.y -= 1
      }
      placed[id] = frame
    }
    return placed
  }

  /// A place for `frame` out of the way of the panel moved onto it: the space that panel left, if it's beside
  /// `frame`, or else just above the moved panel. nil when neither is free, so it goes below instead.
  private static func makeWay(for frame: DashboardGridFrame,
                              around moved: DashboardGridFrame,
                              vacated: DashboardGridFrame?,
                              isFree: (DashboardGridFrame) -> Bool) -> DashboardGridFrame? {
    // Only when moving, not resizing
    guard let vacated = vacated else { return nil }
    let sideways = DashboardGridFrame(x: vacated.x, y: frame.y, w: frame.w, h: frame.h).clamped
    if sideways.x != frame.x && isFree(sideways) {
      return sideways
    }
    let above = DashboardGridFrame(x: frame.x, y: moved.y - frame.h, w: frame.w, h: frame.h)
    if isFree(above) {
      return above
    }
    return nil
  }
}

/// Where grid cells fall on screen, for a grid `width` points wide
public struct DashboardGridMetrics: Equatable {
  /// Narrower than this, panels are shown one under another, full width
  public static let narrowWidth: Double = 700

  public var width: Double

  public init(width: Double) {
    self.width = width
  }

  public var isNarrow: Bool { width < Self.narrowWidth }

  public var columnWidth: Double {
    let columns = Double(DashboardLayout.columns)
    return max((width - (columns - 1) * DashboardLayout.spacing) / columns, 1)
  }

  /// From the left edge of one column to the next, and the top of one row to the next
  public var columnStep: Double { columnWidth + DashboardLayout.spacing }
  public var rowStep: Double { DashboardLayout.rowHeight + DashboardLayout.spacing }

  public func rect(_ frame: DashboardGridFrame) -> CGRect {
    CGRect(x: Double(frame.x) * columnStep,
           y: Double(frame.y) * rowStep,
           width: Double(frame.w) * columnWidth + Double(max(frame.w - 1, 0)) * DashboardLayout.spacing,
           height: DashboardLayout.height(rows: frame.h))
  }

  /// The cell nearest a panel's top left corner at `point`
  public func cell(nearest point: CGPoint) -> (x: Int, y: Int) {
    (x: Int((Double(point.x) / columnStep).rounded()), y: Int((Double(point.y) / rowStep).rounded()))
  }

  /// The size in cells nearest a panel `size` points big
  public func cells(nearest size: CGSize) -> (w: Int, h: Int) {
    (w: Int(((Double(size.width) + DashboardLayout.spacing) / columnStep).rounded()),
     h: Int(((Double(size.height) + DashboardLayout.spacing) / rowStep).rounded()))
  }

  /// How tall the panels are altogether, in points
  public func height(_ frames: DashboardLayout.Frames) -> Double {
    let rows = DashboardLayout.bottom(frames)
    return rows == 0 ? 0 : DashboardLayout.height(rows: rows)
  }

  /// The panels one under another at the full width, in the order given, each keeping its height
  public static func stacked(_ panels: [DashboardPanel]) -> DashboardLayout.Frames {
    var frames = DashboardLayout.Frames()
    var y = 0
    for panel in panels {
      frames[panel.id] = DashboardGridFrame(x: 0, y: y, w: DashboardLayout.columns, h: panel.frame.h)
      y += panel.frame.h
    }
    return frames
  }
}
