// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

import OrderedCollections

struct macosTableRowView: View {

  let row: macosTableRow
  let columns: [macosTableColumn]
  let widths: [macosTableColumn: CGFloat]
  var collapsedColumns: Set<macosTableColumn> = []
  var resizingColumn: macosTableColumn? = nil
  let isSelected: Bool
  let onSelect: () -> Void
  var onHideField: (macosTableColumn) -> Void = { _ in }
  /// Filters the search for a field's value, or against it when negated. No filter buttons without it.
  var onFilter: ((_ field: String, _ value: String, _ negated: Bool) -> Void)? = nil

  @State private var isHovered = false

  var rowBackground: Color {
    if isSelected {
      return Color("BackgroundAlt3")
    }
    return isHovered ? Color("Button") : Color.clear
  }

  func copyToPasteboard(_ value: String) {
#if os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(value, forType: .string)
#else
    UIPasteboard.general.string = value
#endif
  }

  func hideFieldButton(_ column: macosTableColumn) -> some View {
    Button("Hide field") {
      onHideField(column)
    }
  }

  /// The value a field cell can be filtered on: one value, and not the date column, as a filter on an exact
  /// time isn't useful. Nil when the cell has no filter buttons.
  func filterValue(for column: macosTableColumn) -> String? {
    guard onFilter != nil, case .field(let key) = column, !collapsedColumns.contains(column) else {
      return nil
    }
    return row.item[key].flatMap { FieldFilter.make(field: key, values: $0)?.value }
  }

  @ViewBuilder
  func filterButtons(for column: macosTableColumn, value: String) -> some View {
    if case .field(let key) = column, let onFilter = onFilter {
      Button("Filter for value") {
        onFilter(key, value, false)
      }
      Button("Filter out value") {
        onFilter(key, value, true)
      }
      Divider()
    }
  }

  @ViewBuilder
  func cell(for column: macosTableColumn) -> some View {
    switch column {
    case .document:
      row.summary.map { Text($0.attributedString + " ") }.reduce(Text(""), +)
        .lineLimit(3)
        .lineSpacing(3)
        .macosTableCell(width: nil)

    case .date, .field:
      if let value = macosTableSearchView.text(for: column, in: row.item) {
        let cellFilterValue = filterValue(for: column)
        macosTableFilterableCell(column: column, filterValue: cellFilterValue, onFilter: onFilter) {
          Text(collapsedColumns.contains(column) ? "…" : value)
            .font(.system(size: 12))
            .foregroundColor(Color("TextColor"))
            .lineLimit(1)
            .truncationMode(.tail)
            .help(value)
            .accessibilityLabel(value)
            .macosTableCell(width: widths[column],
                            compact: collapsedColumns.contains(column),
                            highlighted: column == resizingColumn)
        }
        .contextMenu {
          Button("Copy value") {
            copyToPasteboard(value)
          }
          Divider()
          if let cellFilterValue = cellFilterValue {
            filterButtons(for: column, value: cellFilterValue)
          }
          hideFieldButton(column)
        }
      } else {
        Text("—")
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary").opacity(0.5))
          .accessibilityLabel("No value")
          .macosTableCell(width: widths[column],
                          compact: collapsedColumns.contains(column),
                          highlighted: column == resizingColumn)
          .contentShape(Rectangle())
          .contextMenu {
            hideFieldButton(column)
          }
      }
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(columns, id: \.self) { column in
        cell(for: column)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(rowBackground)
    .overlay(alignment: .bottom) {
      Rectangle().fill(Color("GridBorder")).frame(height: 1)
    }
    .contentShape(Rectangle())
    .onHover { hovering in
      isHovered = hovering
    }
    .onTapGesture {
      onSelect()
    }
  }
}

/// A table cell that shows buttons to filter for or against its value while the pointer is over it.
/// The hover is kept here, so moving between cells only redraws the two cells, not the row.
struct macosTableFilterableCell<Content: View>: View {
  let column: macosTableColumn
  /// The value to filter on, nil when the cell has no filter buttons
  let filterValue: String?
  let onFilter: ((_ field: String, _ value: String, _ negated: Bool) -> Void)?
  @ViewBuilder let content: Content
  @State private var isHovered = false

  var body: some View {
#if os(macOS)
    if let filterValue = filterValue, let onFilter = onFilter, case .field(let key) = column {
      content
        // Over the end of the value rather than beside it, so narrow columns don't reflow
        .overlay(alignment: .trailing) {
          if isHovered {
            HStack(spacing: 0) {
              DocumentFilterButton(systemImage: "plus.magnifyingglass",
                                   isActive: false,
                                   help: "Filter for value",
                                   accessibilityLabel: "Filter for \(filterValue)") {
                onFilter(key, filterValue, false)
              }
              DocumentFilterButton(systemImage: "minus.magnifyingglass",
                                   isActive: false,
                                   help: "Filter out value",
                                   accessibilityLabel: "Filter out \(filterValue)") {
                onFilter(key, filterValue, true)
              }
            }
            .padding(1)
            .background(Color("ButtonHighlighted"))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(.trailing, 4)
          }
        }
        .onHover { hovering in
          isHovered = hovering
        }
    } else {
      content
    }
#else
    content
#endif
  }
}
