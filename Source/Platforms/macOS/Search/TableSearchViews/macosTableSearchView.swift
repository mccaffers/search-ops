// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

import OrderedCollections

/// A column of the table layout.
/// `document` is the one-column summary shown when no fields are picked in the sidebar.
enum macosTableColumn: Hashable {
  case date(String)
  case field(String)
  case document

  var title: String {
    switch self {
    case .date(let key), .field(let key):
      return key
    case .document:
      return "Document"
    }
  }
}

/// A document row of the table layout, holding the flat row the detail panel expects.
struct macosTableRow {
  let index: Int
  let item: OrderedDictionary<String, Any>
  let summary: [TextModel]
}

struct macosTableSearchView: View {

  @Binding var renderedObjects: RenderObject?
  @ObservedObject var resultsFields: RenderedFields
  @ObservedObject var itemDetail: DocumentDetail

  var filteredFields: [SquashedFieldsArray]
  var showDateHeader: Bool

  @State private var selectedRow: Int? = nil
  @State private var legacyScrollers = Self.usesLegacyScrollers

  func select(_ row: macosTableRow) {
    selectedRow = row.index
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
      itemDetail.item = row.item
    }
  }

  var body: some View {
    VStack {
      if let renderedObjects = renderedObjects, let flatArray = renderedObjects.flat {
        let columns = Self.columns(dateField: renderedObjects.dateField,
                                   showDateHeader: showDateHeader,
                                   filteredFields: filteredFields)
        let rows = Self.visibleRows(flatArray: flatArray,
                                    dateField: renderedObjects.dateField,
                                    filteredFields: filteredFields,
                                    showDateHeader: showDateHeader)
        let widths = Self.columnWidths(columns: columns, rows: rows)

        GeometryReader { geometry in
          // Always-visible scroll bars take their width out of the visible area
          let scrollerWidth = legacyScrollers ? Self.legacyScrollerWidth : 0
          let scrollsSideways = Self.scrollsSideways(columns: columns,
                                                     widths: widths,
                                                     availableWidth: geometry.size.width - scrollerWidth)

          ScrollView(scrollsSideways ? [.horizontal, .vertical] : .vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
              Section {
                ForEach(rows, id: \.index) { row in
                  macosTableRowView(row: row,
                                    columns: columns,
                                    widths: widths,
                                    isSelected: selectedRow == row.index,
                                    onSelect: { select(row) })
                }

                if !filteredFields.isEmpty {
                  Text("Fields are being filtered by your selection. Documents will not be shown if they do not have any of the selected fields.")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .font(.system(size: 14))
                    .frame(maxWidth: geometry.size.width, alignment: .leading)
                }
              } header: {
                macosTableHeaderView(columns: columns, widths: widths)
              }
            }
            // Before macOS 14 the anchor below isn't available, so fill the scroll view to stop it centring the table
            .frame(minWidth: scrollsSideways && Self.needsFillToAlignTop ? geometry.size.width : nil,
                   minHeight: scrollsSideways && Self.needsFillToAlignTop ? geometry.size.height : nil,
                   alignment: .topLeading)
          }
          // A two-way scroll view centres content smaller than itself, which also moves the pinned header
          .macosTopLeadingScrollAnchor()
        }
        .background(Color("BackgroundAlt"))
        .clipShape(.rect(cornerRadius: 5))

      } else {
        Spacer()
      }
    }
    .padding(.top, 0.1)
    .onChange(of: itemDetail.showingView) { newValue in
      if !newValue {
        selectedRow = nil
      }
    }
#if os(macOS)
    .onReceive(NotificationCenter.default.publisher(for: NSScroller.preferredScrollerStyleDidChangeNotification)) { _ in
      legacyScrollers = Self.usesLegacyScrollers
    }
#endif
  }
}

struct macosTableHeaderView: View {
  let columns: [macosTableColumn]
  let widths: [macosTableColumn: CGFloat]

  var body: some View {
    HStack(spacing: 0) {
      ForEach(columns, id: \.self) { column in
        Text(column.title)
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(Color("LabelBackgroundFocus"))
          .lineLimit(1)
          .truncationMode(.middle)
          .help(column.title)
          .macosTableCell(width: widths[column])
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .overlay(alignment: .bottom) {
      Rectangle().fill(Color("GridBorder")).frame(height: 1)
    }
  }
}

extension View {
  /// Keeps content that's smaller than the scroll view at its top-left corner.
  @ViewBuilder
  func macosTopLeadingScrollAnchor() -> some View {
    if #available(macOS 14.0, iOS 17.0, *) {
      self.defaultScrollAnchor(.topLeading)
    } else {
      self
    }
  }

  /// Pads a table cell, fixes its width (or lets it fill the row when `width` is nil) and draws its right border.
  func macosTableCell(width: CGFloat?) -> some View {
    self
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .frame(width: width, alignment: .topLeading)
      .frame(maxWidth: width == nil ? .infinity : nil, maxHeight: .infinity, alignment: .topLeading)
      .overlay(alignment: .trailing) {
        Rectangle().fill(Color("GridBorder")).frame(width: 1)
      }
  }
}

extension macosTableSearchView {
  static let minColumnWidth: CGFloat = 60
  static let maxColumnWidth: CGFloat = 300
  /// Horizontal padding inside a cell, plus a little slack for rounding.
  static let cellPadding: CGFloat = 22

  /// The date column comes first when it's shown, then the fields picked in the sidebar,
  /// or a single document summary column when none are picked.
  static func columns(dateField: SquashedFieldsArray?,
                      showDateHeader: Bool,
                      filteredFields: [SquashedFieldsArray]) -> [macosTableColumn] {
    var columns = [macosTableColumn]()
    if showDateHeader, let dateField = dateField {
      columns.append(.date(dateField.squashedString))
    }
    if filteredFields.isEmpty {
      columns.append(.document)
    } else {
      columns.append(contentsOf: filteredFields.map { .field($0.squashedString) })
    }
    return columns
  }

  /// The rows the document layout would show, in the same order.
  static func visibleRows(flatArray: [OrderedDictionary<String, Any>],
                          dateField: SquashedFieldsArray?,
                          filteredFields: [SquashedFieldsArray],
                          showDateHeader: Bool) -> [macosTableRow] {
    flatArray.indices.compactMap { index in
      let row = macOSDocumentSearchView.processRow(item: flatArray[index],
                                                   dateField: dateField,
                                                   filteredFields: filteredFields,
                                                   showDateHeader: showDateHeader)
      return row.shouldShowRow ? macosTableRow(index: index, item: row.item, summary: row.myDic) : nil
    }
  }

  /// The non-blank values of a field. A missing key, `[""]` and whitespace-only values all count as missing,
  /// matching what the document layout skips.
  static func values(for key: String, in item: OrderedDictionary<String, Any>) -> [String] {
    guard let values = item[key] as? [String] else { return [] }
    return values.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
  }

  /// The text of a field cell: every value joined into one line, or nil when the field is missing.
  static func cellText(for key: String, in item: OrderedDictionary<String, Any>) -> String? {
    let found = values(for: key, in: item)
    return found.isEmpty ? nil : found.joined(separator: ", ")
  }

  /// The date cell's text, formatted like the document layout, falling back to the raw value.
  static func dateText(for key: String, in item: OrderedDictionary<String, Any>) -> String? {
    guard let raw = values(for: key, in: item).first else { return nil }
    let formatted = DateTools.buildDateLarge(input: raw)
    return formatted.isEmpty ? raw : formatted
  }

  static func text(for column: macosTableColumn, in item: OrderedDictionary<String, Any>) -> String? {
    switch column {
    case .date(let key):
      return dateText(for: key, in: item)
    case .field(let key):
      return cellText(for: key, in: item)
    case .document:
      return nil
    }
  }

  /// Sizes each field column to its widest header or value, between the minimum and maximum widths.
  /// The document column has no entry, so it fills the rest of the row.
  static func columnWidths(columns: [macosTableColumn],
                           rows: [macosTableRow],
                           measure: (_ text: String, _ bold: Bool) -> CGFloat = macosTableSearchView.measureText(_:bold:)) -> [macosTableColumn: CGFloat] {
    var widths = [macosTableColumn: CGFloat]()
    for column in columns where column != .document {
      var widest = measure(column.title, true)
      for row in rows {
        if let value = text(for: column, in: row.item) {
          // Long values are cut off at the maximum width anyway, so don't measure all of them
          widest = max(widest, measure(String(value.prefix(120)), false))
        }
      }
      widths[column] = min(max(widest + cellPadding, minColumnWidth), maxColumnWidth)
    }
    return widths
  }

  /// Field columns scroll sideways only when they're wider than the visible area.
  /// The document column wraps to the view's width instead.
  static func scrollsSideways(columns: [macosTableColumn],
                              widths: [macosTableColumn: CGFloat],
                              availableWidth: CGFloat) -> Bool {
    guard !columns.contains(.document) else { return false }
    return widths.values.reduce(0, +) > availableWidth
  }

  static var needsFillToAlignTop: Bool {
    if #available(macOS 14.0, iOS 17.0, *) {
      return false
    }
    return true
  }

  static var usesLegacyScrollers: Bool {
#if os(macOS)
    NSScroller.preferredScrollerStyle == .legacy
#else
    false
#endif
  }

  static var legacyScrollerWidth: CGFloat {
#if os(macOS)
    NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy)
#else
    0
#endif
  }

  static func measureText(_ text: String, bold: Bool) -> CGFloat {
#if os(macOS)
    let font = NSFont.systemFont(ofSize: 12, weight: bold ? .semibold : .regular)
#else
    let font = UIFont.systemFont(ofSize: 12, weight: bold ? .semibold : .regular)
#endif
    return ceil((text as NSString).size(withAttributes: [.font: font]).width)
  }
}
