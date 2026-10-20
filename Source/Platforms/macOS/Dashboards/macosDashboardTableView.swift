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
/// so panels side by side line up whatever they find.
struct macosDashboardTableView: View {
  var columns: [DashboardColumn]
  var rows: [DashboardRow]
  var rowLimit: Int

  static let rowHeight: CGFloat = 22
  static let headerHeight: CGFloat = 24
  static let dateWidth: CGFloat = 165

  static func height(rowLimit: Int) -> CGFloat {
    headerHeight + CGFloat(rowLimit) * rowHeight
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      line(cells: columns.map(\.title), header: true)
        .frame(height: Self.headerHeight)

      ForEach(Array(rows.prefix(rowLimit).enumerated()), id: \.element.id) { offset, row in
        line(cells: row.cells, header: false)
          .frame(height: Self.rowHeight)
          .background(offset.isMultiple(of: 2) ? Color("BackgroundAlt").opacity(0.5) : Color.clear)
          .clipShape(RoundedRectangle(cornerRadius: 5))
      }

      Spacer(minLength: 0)
    }
    .frame(height: Self.height(rowLimit: rowLimit), alignment: .top)
  }

  private func line(cells: [String?], header: Bool) -> some View {
    HStack(spacing: 10) {
      ForEach(Array(zip(columns, cells).enumerated()), id: \.offset) { _, pair in
        cell(pair.1, column: pair.0, header: header)
      }
    }
    .padding(.horizontal, 6)
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
        .frame(width: Self.dateWidth, alignment: .leading)
    case .field, .document:
      label
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
#endif
