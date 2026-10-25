// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

/// A panel's documents as a small table: a header and one line per document. Always as tall as `rowLimit` lines,
/// so panels side by side line up whatever they find. Columns are drawn at `DashboardColumnWidths`, the last one
/// filling the row. In edit mode, dragging a column's right border resizes it, and double-clicking one fits every
/// column to its contents.
struct macosDashboardTableView: View {
  var columns: [DashboardColumn]
  var rows: [DashboardRow]
  var rowLimit: Int
  /// The width each column would like
  var preferredWidths: [DashboardColumn: Double]
  /// The columns someone sized, which give way last when the table is narrow
  var setColumns: Set<DashboardColumn>
  var isEditing = false
  /// A column dragged to a new width, once it's let go
  var onResizeColumn: (DashboardColumn, Double) -> Void = { _, _ in }
  /// A border double-clicked
  var onFitColumns: () -> Void = {}

  /// A column border being dragged
  struct Resize {
    let column: DashboardColumn
    let startWidth: Double
    var width: Double
  }

  @State private var resize: Resize? = nil
  @State private var hoveredBorder: DashboardColumn? = nil

  static let rowHeight = CGFloat(DashboardLayout.tableRowHeight)
  static let headerHeight = CGFloat(DashboardLayout.tableHeaderHeight)
  /// Inside each cell, either side of its text
  static let cellInset: CGFloat = 6

  static func height(rowLimit: Int) -> CGFloat {
    headerHeight + CGFloat(rowLimit) * rowHeight
  }

  var body: some View {
    GeometryReader { geometry in
      let widths = drawnWidths(available: geometry.size.width)
      VStack(alignment: .leading, spacing: 0) {
        line(cells: columns.map(\.title), widths: widths, header: true)
          .frame(height: Self.headerHeight)

        ForEach(Array(rows.prefix(rowLimit).enumerated()), id: \.element.id) { offset, row in
          line(cells: row.cells, widths: widths, header: false)
            .frame(height: Self.rowHeight)
            .background(offset.isMultiple(of: 2) ? Color("BackgroundAlt").opacity(0.5) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }

        Spacer(minLength: 0)
      }
      .frame(width: geometry.size.width, alignment: .topLeading)
      .clipped()
      .overlay(alignment: .topLeading) {
        if isEditing {
          borders(widths: widths, height: geometry.size.height)
        }
      }
    }
    .frame(height: Self.height(rowLimit: rowLimit), alignment: .top)
    .textSelection(.enabled)
  }

  /// The widths the columns are drawn at, the one being dragged following the pointer
  private func drawnWidths(available: CGFloat) -> [CGFloat] {
    var preferred = preferredWidths
    var set = setColumns
    if let resize = resize {
      preferred[resize.column] = resize.width
      set.insert(resize.column)
    }
    return DashboardColumnWidths.fitted(columns: columns,
                                        preferred: preferred,
                                        set: set,
                                        available: Double(available)).map { CGFloat($0) }
  }

  /// A grab area and line on the right border of every column but the last, which fills the row
  private func borders(widths: [CGFloat], height: CGFloat) -> some View {
    ZStack(alignment: .topLeading) {
      ForEach(Array(columns.dropLast().enumerated()), id: \.offset) { index, column in
        let x = widths.prefix(index + 1).reduce(0, +)
        let highlighted = hoveredBorder == column || resize?.column == column
        Rectangle()
          .fill(highlighted ? Color.accentColor : Color("GridBorder"))
          .frame(width: highlighted ? 3 : 1, height: height)
          .offset(x: x - (highlighted ? 1.5 : 0.5))
          .allowsHitTesting(false)
        macosTableResizeHandle(onHover: { hovering in
                                 if hovering {
                                   hoveredBorder = column
                                 } else if hoveredBorder == column {
                                   hoveredBorder = nil
                                 }
                               },
                               onDrag: { translation in
                                 let start = resize?.startWidth ?? Double(widths[index])
                                 resize = Resize(column: column,
                                                 startWidth: start,
                                                 width: DashboardColumnWidths.clampedSetWidth(start + Double(translation)))
                               },
                               onDragEnd: {
                                 if let resize = resize {
                                   onResizeColumn(resize.column, resize.width)
                                 }
                                 resize = nil
                               },
                               onDoubleClick: onFitColumns)
          .frame(width: macosTableHeaderView.handleWidth, height: height)
          .offset(x: x - macosTableHeaderView.handleWidth / 2)
      }
    }
  }

  private func line(cells: [String?], widths: [CGFloat], header: Bool) -> some View {
    HStack(spacing: 0) {
      ForEach(Array(zip(columns, cells).enumerated()), id: \.offset) { index, pair in
        cell(pair.1, column: pair.0, header: header)
          .padding(.horizontal, Self.cellInset)
          .frame(width: index < widths.count ? widths[index] : nil, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func cell(_ text: String?, column: DashboardColumn, header: Bool) -> some View {
    let label = Text(text ?? (header ? "" : "–"))
      .font(.system(size: 12, weight: header ? .semibold : .regular))
      .foregroundColor(Color(header || text == nil ? "TextSecondary" : "TextColor"))
      .lineLimit(1)
      .truncationMode(.tail)
      .help(text ?? "")
    switch column {
    case .date:
      label
        .monospacedDigit()
    case .field, .document:
      label
    }
  }
}
#endif
