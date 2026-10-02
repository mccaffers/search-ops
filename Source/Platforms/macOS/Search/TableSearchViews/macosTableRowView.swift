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
  let isSelected: Bool
  let onSelect: () -> Void

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
        Text(value)
          .font(.system(size: 12))
          .foregroundColor(Color("TextColor"))
          .lineLimit(1)
          .truncationMode(.tail)
          .help(value)
          .macosTableCell(width: widths[column])
          .contextMenu {
            Button("Copy value") {
              copyToPasteboard(value)
            }
          }
      } else {
        Text("—")
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary").opacity(0.5))
          .accessibilityLabel("No value")
          .macosTableCell(width: widths[column])
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
