// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing

@testable import Search_Ops

struct DashboardLayoutTests {

  private func frame(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> DashboardGridFrame {
    DashboardGridFrame(x: x, y: y, w: w, h: h)
  }

  /// No two panels share a cell, and every panel is inside the grid
  private func isValid(_ frames: DashboardLayout.Frames) -> Bool {
    let all = Array(frames.values)
    for (index, a) in all.enumerated() {
      if a != a.clamped {
        return false
      }
      for b in all[(index + 1)...] where a.overlaps(b) {
        return false
      }
    }
    return true
  }

  // MARK: - Frames

  @Test func framesOverlapOnlyWhenTheyShareACell() {
    #expect(frame(0, 0, 6, 3).overlaps(frame(5, 2, 2, 2)))
    // Touching edges isn't overlapping
    #expect(!frame(0, 0, 6, 3).overlaps(frame(6, 0, 6, 3)))
    #expect(!frame(0, 0, 6, 3).overlaps(frame(0, 3, 6, 3)))
  }

  @Test func framesAreKeptInsideTheGridAndNoSmallerThanTheSmallestPanel() {
    #expect(frame(-3, -1, 1, 1).clamped == frame(0, 0, DashboardLayout.minWidth, DashboardLayout.minHeight))
    #expect(frame(10, 0, 6, 3).clamped == frame(6, 0, 6, 3))
    #expect(frame(0, 0, 20, 99).clamped == frame(0, 0, 12, DashboardLayout.maxHeight))
  }

  // MARK: - Sizes

  @Test func tallerPanelsSearchForMoreDocuments() {
    #expect(DashboardLayout.rowLimit(height: DashboardLayout.minHeight) == 1)
    #expect(DashboardLayout.rowLimit(height: DashboardLayout.defaultHeight) == 10)
    #expect(DashboardLayout.rowLimit(height: 12) > DashboardLayout.rowLimit(height: 11))
    #expect(DashboardLayout.rowLimit(height: DashboardLayout.maxHeight) <= DashboardLayout.maxRowLimit)
  }

  @Test func heightFittingIsTheLowestThatShowsThatManyDocuments() {
    for documents in [1, 5, 10, 20] {
      let h = DashboardLayout.height(fitting: documents)
      #expect(DashboardLayout.rowLimit(height: h) >= documents)
      #expect(h == DashboardLayout.minHeight || DashboardLayout.rowLimit(height: h - 1) < documents)
    }
  }

  // MARK: - Compacting

  @Test func panelsRiseToFillTheGapAboveThem() {
    let a = UUID(), b = UUID()
    let compacted = DashboardLayout.compact([a: frame(0, 4, 6, 3), b: frame(6, 9, 6, 3)])
    #expect(compacted == [a: frame(0, 0, 6, 3), b: frame(6, 0, 6, 3)])
  }

  @Test func aPanelRestsOnThePanelBelowIt() {
    let a = UUID(), b = UUID()
    let compacted = DashboardLayout.compact([a: frame(0, 0, 12, 3), b: frame(4, 8, 4, 3)])
    #expect(compacted[b] == frame(4, 3, 4, 3))
  }

  @Test func overlappingPanelsArePushedApart() {
    let a = UUID(), b = UUID()
    let compacted = DashboardLayout.compact([a: frame(0, 0, 6, 4), b: frame(2, 1, 6, 3)])
    #expect(compacted == [a: frame(0, 0, 6, 4), b: frame(2, 4, 6, 3)])
  }

  // MARK: - Moving

  @Test func movingAPanelOntoItsNeighbourSwapsThem() {
    let a = UUID(), b = UUID()
    let frames = [a: frame(0, 0, 6, 4), b: frame(6, 0, 6, 4)]
    #expect(DashboardLayout.move(frames, id: a, to: frame(6, 0, 6, 4)) == [a: frame(6, 0, 6, 4), b: frame(0, 0, 6, 4)])
  }

  @Test func movingAPanelDownPastTheOneBelowSwapsThem() {
    let a = UUID(), b = UUID()
    let frames = [a: frame(0, 0, 12, 3), b: frame(0, 3, 12, 3)]
    // A small nudge isn't enough
    #expect(DashboardLayout.move(frames, id: a, to: frame(0, 1, 12, 3)) == frames)
    // Its top reaching the other's top is
    #expect(DashboardLayout.move(frames, id: a, to: frame(0, 3, 12, 3)) == [a: frame(0, 3, 12, 3), b: frame(0, 0, 12, 3)])
  }

  @Test func movingAPanelUpPastTheOneAboveSwapsThem() {
    let a = UUID(), b = UUID(), c = UUID()
    let frames = [a: frame(0, 0, 12, 3), b: frame(0, 3, 12, 3), c: frame(0, 6, 12, 3)]
    let moved = DashboardLayout.move(frames, id: c, to: frame(0, 3, 12, 3))
    #expect(moved == [a: frame(0, 0, 12, 3), c: frame(0, 3, 12, 3), b: frame(0, 6, 12, 3)])
  }

  @Test func aPanelMovesIntoTheGapBesideATallerOne() {
    let a = UUID(), b = UUID(), c = UUID(), d = UUID()
    // A short panel beside a tall one leaves a gap under it
    let frames = [a: frame(0, 0, 6, 3), b: frame(6, 0, 6, 8), d: frame(0, 8, 12, 3), c: frame(0, 11, 6, 3)]
    let moved = DashboardLayout.move(frames, id: c, to: frame(0, 3, 6, 3))
    #expect(moved == [a: frame(0, 0, 6, 3), b: frame(6, 0, 6, 8), c: frame(0, 3, 6, 3), d: frame(0, 8, 12, 3)])
  }

  @Test func movedPanelsStayInsideTheGrid() {
    let a = UUID()
    let moved = DashboardLayout.move([a: frame(0, 0, 6, 3)], id: a, to: frame(10, -4, 6, 3))
    #expect(moved == [a: frame(6, 0, 6, 3)])
  }

  @Test func pushesCascadeDownTheColumn() {
    let a = UUID(), b = UUID(), c = UUID(), d = UUID()
    let frames = [a: frame(0, 0, 4, 3), b: frame(4, 0, 8, 3), c: frame(4, 3, 8, 3), d: frame(0, 3, 4, 3)]
    // A over the left half of B and C: both have to go below it
    let moved = DashboardLayout.move(frames, id: a, to: frame(4, 0, 4, 3))
    #expect(isValid(moved))
    #expect(moved[a] == frame(4, 0, 4, 3))
    #expect(moved[b]!.y >= 3)
    #expect(moved[c]!.y >= moved[b]!.maxY)
  }

  @Test func movingAPanelThatIsntThereChangesNothing() {
    let a = UUID()
    let frames = [a: frame(0, 0, 6, 3)]
    #expect(DashboardLayout.move(frames, id: UUID(), to: frame(6, 0, 6, 3)) == frames)
    #expect(DashboardLayout.resize(frames, id: UUID(), to: frame(0, 0, 12, 9)) == frames)
  }

  // MARK: - Resizing

  @Test func wideningAPanelPushesItsNeighbourBelow() {
    let a = UUID(), b = UUID()
    let frames = [a: frame(0, 0, 6, 4), b: frame(6, 0, 6, 4)]
    let resized = DashboardLayout.resize(frames, id: a, to: frame(0, 0, 8, 4))
    #expect(resized == [a: frame(0, 0, 8, 4), b: frame(6, 4, 6, 4)])
  }

  @Test func shrinkingAPanelLetsThePanelsBelowRise() {
    let a = UUID(), b = UUID()
    let frames = [a: frame(0, 0, 12, 8), b: frame(0, 8, 6, 3)]
    let resized = DashboardLayout.resize(frames, id: a, to: frame(0, 0, 12, 4))
    #expect(resized == [a: frame(0, 0, 12, 4), b: frame(0, 4, 6, 3)])
  }

  @Test func resizedPanelsStayInsideTheGrid() {
    let a = UUID()
    let resized = DashboardLayout.resize([a: frame(8, 0, 4, 3)], id: a, to: frame(0, 0, 9, 1))
    #expect(resized == [a: frame(3, 0, 9, DashboardLayout.minHeight)])
  }

  // MARK: - Adding and removing

  @Test func aNewPanelFillsTheFirstGapItFits() {
    let a = UUID(), b = UUID()
    let frames = [a: frame(0, 0, 6, 3), b: frame(6, 0, 6, 10)]
    #expect(DashboardLayout.insertionFrame(frames, w: 6, h: 7) == frame(0, 3, 6, 7))
    // Too wide for the gap: below everything
    #expect(DashboardLayout.insertionFrame(frames, w: 8, h: 3) == frame(0, 10, 8, 3))
    #expect(DashboardLayout.insertionFrame([:]) == frame(0, 0, DashboardLayout.defaultWidth, DashboardLayout.defaultHeight))
  }

  @Test func removingAPanelLetsThePanelsBelowRise() {
    let a = UUID(), b = UUID(), c = UUID()
    let frames = [a: frame(0, 0, 6, 5), b: frame(6, 0, 6, 3), c: frame(0, 5, 6, 3)]
    #expect(DashboardLayout.remove(frames, id: a) == [b: frame(6, 0, 6, 3), c: frame(0, 0, 6, 3)])
  }

  @Test func bottomIsTheLowestEdge() {
    #expect(DashboardLayout.bottom([:]) == 0)
    #expect(DashboardLayout.bottom([UUID(): frame(0, 2, 6, 3), UUID(): frame(6, 0, 6, 9)]) == 9)
  }

  // MARK: - Dashboards saved before the grid

  @Test func oldLayoutsBecomeRowsOfEqualPanels() {
    let ids = (0..<4).map { _ in UUID() }
    let panels = ids.map { DashboardLayout.LegacyPanel(id: $0, fullWidth: false, documents: 10) }
    let h = DashboardLayout.height(fitting: 10)
    let frames = DashboardLayout.legacyFrames(panels, columns: 3)
    #expect(frames[ids[0]] == frame(0, 0, 4, h))
    #expect(frames[ids[2]] == frame(8, 0, 4, h))
    #expect(frames[ids[3]] == frame(0, h, 4, h))
    // 0 columns read as the old default of 2
    #expect(DashboardLayout.legacyFrames(panels, columns: 0)[ids[1]] == frame(6, 0, 6, h))
  }

  @Test func oldFullWidthPanelsTakeARowOfTheirOwn() {
    let a = UUID(), wide = UUID(), b = UUID()
    let frames = DashboardLayout.legacyFrames([DashboardLayout.LegacyPanel(id: a, fullWidth: false, documents: 5),
                                               DashboardLayout.LegacyPanel(id: wide, fullWidth: true, documents: 5),
                                               DashboardLayout.LegacyPanel(id: b, fullWidth: false, documents: 5)],
                                              columns: 2)
    let h = DashboardLayout.height(fitting: 5)
    #expect(frames[a] == frame(0, 0, 6, h))
    #expect(frames[wide] == frame(0, h, 12, h))
    #expect(frames[b] == frame(0, 2 * h, 6, h))
  }

  // MARK: - Never overlapping

  @Test func randomMovesAndResizesNeverOverlapOrLeaveGaps() {
    var generator = SeededGenerator(seed: 42)
    let ids = (0..<8).map { _ in UUID() }
    var frames = DashboardLayout.Frames()
    for id in ids {
      frames[id] = DashboardLayout.insertionFrame(frames,
                                                  w: Int.random(in: 2...12, using: &generator),
                                                  h: Int.random(in: 3...10, using: &generator))
    }
    #expect(isValid(frames))
    for _ in 0..<500 {
      let id = ids.randomElement(using: &generator)!
      if Bool.random(using: &generator) {
        frames = DashboardLayout.move(frames, id: id, to: frame(Int.random(in: -2...13, using: &generator),
                                                                 Int.random(in: -2...40, using: &generator), 1, 1))
      } else {
        frames = DashboardLayout.resize(frames, id: id, to: frame(0, 0,
                                                                   Int.random(in: 0...14, using: &generator),
                                                                   Int.random(in: 0...14, using: &generator)))
      }
      #expect(isValid(frames))
      #expect(frames.count == ids.count)
      // Nothing could rise any further
      #expect(DashboardLayout.compact(frames) == frames)
    }
  }
}

/// Repeatable random numbers, so a failing run can be replayed
private struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    // SplitMix64
    state &+= 0x9E3779B97F4A7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
  }
}

struct DashboardGridMetricsTests {

  // 12 columns of 50 and 11 gaps of 10
  let metrics = DashboardGridMetrics(width: 710)

  private func cell(_ point: CGPoint) -> [Int] {
    let cell = metrics.cell(nearest: point)
    return [cell.x, cell.y]
  }

  private func cells(_ size: CGSize) -> [Int] {
    let cells = metrics.cells(nearest: size)
    return [cells.w, cells.h]
  }

  @Test func cellsAreSpreadAcrossTheWidth() {
    #expect(metrics.columnWidth == 50)
    #expect(metrics.rect(DashboardGridFrame(x: 0, y: 0, w: 12, h: 3)).width == 710)
    let rect = metrics.rect(DashboardGridFrame(x: 2, y: 1, w: 3, h: 3))
    #expect(rect == CGRect(x: 120, y: 50, width: 170, height: 140))
  }

  @Test func pointsSnapToTheNearestCell() {
    #expect(cell(CGPoint(x: 120, y: 50)) == [2, 1])
    #expect(cell(CGPoint(x: 150, y: 74)) == [3, 1])
    #expect(cell(CGPoint(x: -20, y: -10)) == [0, 0])
    #expect(cells(CGSize(width: 170, height: 140)) == [3, 3])
    #expect(cells(CGSize(width: 200, height: 170)) == [4, 4])
  }

  @Test func narrowWindowsStackThePanels() {
    #expect(DashboardGridMetrics(width: 699).isNarrow)
    #expect(!DashboardGridMetrics(width: 700).isNarrow)
    let a = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 0, y: 0, w: 6, h: 4))
    let b = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 6, y: 0, w: 6, h: 7))
    #expect(DashboardGridMetrics.stacked([a, b]) == [a.id: DashboardGridFrame(x: 0, y: 0, w: 12, h: 4),
                                                     b.id: DashboardGridFrame(x: 0, y: 4, w: 12, h: 7)])
  }

  @Test func theHeightIsTheLowestPanelsBottom() {
    #expect(metrics.height([:]) == 0)
    #expect(metrics.height([UUID(): DashboardGridFrame(x: 0, y: 1, w: 6, h: 3)]) == DashboardLayout.height(rows: 4))
  }
}
