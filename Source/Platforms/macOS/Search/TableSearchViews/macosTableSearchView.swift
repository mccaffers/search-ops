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

  /// How a saved search keys the column's width, eg. "field:dayClose"
  var savedKey: String {
    switch self {
    case .date(let key): return "date:\(key)"
    case .field(let key): return "field:\(key)"
    case .document: return "document"
    }
  }

  init?(savedKey: String) {
    if savedKey == "document" {
      self = .document
    } else if savedKey.hasPrefix("date:") {
      self = .date(String(savedKey.dropFirst("date:".count)))
    } else if savedKey.hasPrefix("field:") {
      self = .field(String(savedKey.dropFirst("field:".count)))
    } else {
      return nil
    }
  }

  /// Column widths as a saved search keeps them
  static func savedWidths(_ widths: [macosTableColumn: CGFloat]) -> [String: Double] {
    Dictionary(widths.map { ($0.key.savedKey, Double($0.value)) }, uniquingKeysWith: { first, _ in first })
  }

  /// A saved search's column widths, leaving out any it can't read
  static func widths(fromSaved saved: [String: Double]) -> [macosTableColumn: CGFloat] {
    var widths: [macosTableColumn: CGFloat] = [:]
    for (key, width) in saved {
      if let column = macosTableColumn(savedKey: key), width > 0 {
        widths[column] = CGFloat(width)
      }
    }
    return widths
  }
}

/// A document row of the table layout, holding the flat row the detail panel expects.
struct macosTableRow {
  let index: Int
  let item: OrderedDictionary<String, Any>
  let summary: [TextModel]
  /// Where the document lives, for saving it
  var ref: DocumentRef? = nil
}

/// What the rows and automatic widths are built from. Only the set of picked fields counts, not their order,
/// as reordering them moves columns without changing any row or width.
struct macosTableLayoutKey: Equatable {
  let resultsID: UUID
  let fieldsVersion: UUID
  let dateKey: String?
  let showDateHeader: Bool
  let fieldKeys: Set<String>
  /// The data view's labels change the headers, and so the widths
  var labels: [String: String] = [:]
}

/// The rows of the table and the widths of its columns, which take a pass over every cell to build.
struct macosTableLayout {
  let rows: [macosTableRow]
  let autoWidths: [macosTableColumn: CGFloat]
  let titleWidths: [macosTableColumn: CGFloat]
}

/// Keeps the last layout built, so redrawing the table without new results or a new field selection
/// doesn't measure every cell again.
final class macosTableLayoutCache {
  private var key: macosTableLayoutKey?
  private var layout: macosTableLayout?
  /// Widths measured for the current results, which a new layout reuses for the columns it already had.
  let widths = macosTableWidthCache()

  func layout(for key: macosTableLayoutKey, build: () -> macosTableLayout) -> macosTableLayout {
    if let layout = layout, self.key == key {
      return layout
    }
    widths.use(resultsID: key.resultsID)
    let built = build()
    self.key = key
    layout = built
    return built
  }
}

/// Cell and header widths measured for one set of results. Picking more fields then measures only the new
/// columns, and hiding fields or showing other rows measures only cells not seen before.
final class macosTableWidthCache {
  private struct HeaderKey: Hashable {
    let column: macosTableColumn
    let label: String?
  }

  private var resultsID: UUID?
  /// Each cell's width over its first `autoMeasureLength` characters, by column and then row index
  private var cellWidths = [macosTableColumn: [Int: CGFloat]]()
  private var headerWidths = [HeaderKey: CGFloat]()

  /// Forgets every width when the results change, as the row indices then stand for other documents.
  func use(resultsID: UUID) {
    guard self.resultsID != resultsID else { return }
    self.resultsID = resultsID
    cellWidths = [:]
    headerWidths = [:]
  }

  func headerWidth(_ column: macosTableColumn,
                   labels: [String: String],
                   measure: (_ text: String, _ bold: Bool) -> CGFloat) -> CGFloat {
    let key = HeaderKey(column: column, label: macosTableSearchView.label(for: column, labels: labels))
    if let width = headerWidths[key] {
      return width
    }
    let width = macosTableSearchView.headerWidth(column, labels: labels, measure: measure)
    headerWidths[key] = width
    return width
  }

  /// The widest of the column's cells in `rows`, measured up to `autoMeasureLength` characters.
  func widestCell(_ column: macosTableColumn,
                  rows: [macosTableRow],
                  measure: (_ text: String, _ bold: Bool) -> CGFloat) -> CGFloat {
    var widths = cellWidths[column] ?? [:]
    var widest: CGFloat = 0
    for row in rows {
      let width: CGFloat
      if let measured = widths[row.index] {
        width = measured
      } else {
        width = macosTableSearchView.cellWidth(column, in: row,
                                               measuredLength: macosTableSearchView.autoMeasureLength,
                                               measure: measure)
        widths[row.index] = width
      }
      widest = max(widest, width)
    }
    cellWidths[column] = widths
    return widest
  }
}

struct macosTableSearchView: View {

  @Binding var renderedObjects: RenderObject?
  @ObservedObject var resultsFields: RenderedFields
  @ObservedObject var itemDetail: DocumentDetail

  var filteredFields: [SquashedFieldsArray]
  /// Changes each time a field is picked or hidden, so the table updates in place rather than being rebuilt.
  var fieldsVersion: UUID
  var showDateHeader: Bool
  /// The data view's field labels, shown in the headers above the field paths
  var labels: [String: String] = [:]
  /// Column widths set by dragging a column border or double-clicking one, kept for the search session.
  @Binding var setWidths: [macosTableColumn: CGFloat]
  /// Hides the field behind a column, from the right-click menu of its header or cells.
  var onHideField: (macosTableColumn) -> Void = { _ in }
  /// Opens a document in the Document panel when its row is clicked.
  var onOpenDocument: (OrderedDictionary<String, Any>, DocumentRef?) -> Void
  /// Filters the search for a field's value, or against it when negated, from a cell's buttons or menu.
  var onFilter: ((_ field: String, _ value: String, _ negated: Bool) -> Void)? = nil

  /// Rows and widths from an earlier redraw, so opening a document or a redraw of the search screen
  /// doesn't rebuild them.
  @State private var layoutCache = macosTableLayoutCache()

  var body: some View {
    VStack {
      if let renderedObjects = renderedObjects, let flatArray = renderedObjects.flat {
        let columns = Self.columns(dateField: renderedObjects.dateField,
                                   showDateHeader: showDateHeader,
                                   filteredFields: filteredFields)
        let key = Self.layoutKey(renderedObjects: renderedObjects,
                                 fieldsVersion: fieldsVersion,
                                 filteredFields: filteredFields,
                                 showDateHeader: showDateHeader,
                                 labels: labels)
        let layout = layoutCache.layout(for: key) {
          Self.layout(flatArray: flatArray,
                      refs: renderedObjects.refs,
                      dateField: renderedObjects.dateField,
                      filteredFields: filteredFields,
                      showDateHeader: showDateHeader,
                      columns: columns,
                      labels: labels,
                      widthCache: layoutCache.widths)
        }

        // Rows are built and cells measured here, so dragging a column border in the grid doesn't redo either
        macosTableGridView(columns: columns,
                           rows: layout.rows,
                           autoWidths: layout.autoWidths,
                           titleWidths: layout.titleWidths,
                           labels: labels,
                           setWidths: $setWidths,
                           itemDetail: itemDetail,
                           showsFilterNote: !filteredFields.isEmpty,
                           onHideField: onHideField,
                           onOpenDocument: onOpenDocument,
                           onFilter: onFilter)
      } else {
        Spacer()
      }
    }
    .padding(.top, 0.1)
  }
}

/// A column border being dragged: the width the column had when the drag started and its width now.
struct macosTableResize: Equatable {
  let column: macosTableColumn
  let startWidth: CGFloat
  var width: CGFloat
}

/// The scrolling header and rows of the table layout. It keeps the state of a column border drag to itself,
/// so resizing a column only redraws the grid.
struct macosTableGridView: View {

  let columns: [macosTableColumn]
  let rows: [macosTableRow]
  let autoWidths: [macosTableColumn: CGFloat]
  let titleWidths: [macosTableColumn: CGFloat]
  var labels: [String: String] = [:]
  @Binding var setWidths: [macosTableColumn: CGFloat]
  @ObservedObject var itemDetail: DocumentDetail
  let showsFilterNote: Bool
  var onHideField: (macosTableColumn) -> Void = { _ in }
  var onOpenDocument: (OrderedDictionary<String, Any>, DocumentRef?) -> Void
  var onFilter: ((_ field: String, _ value: String, _ negated: Bool) -> Void)? = nil

  @State private var selectedRow: Int? = nil
  @State private var legacyScrollers = macosTableSearchView.usesLegacyScrollers
  @State private var resize: macosTableResize? = nil

  func select(_ row: macosTableRow) {
    selectedRow = row.index
    onOpenDocument(row.item, row.ref)
  }

  /// The widths the columns are drawn at, including the column being dragged.
  var widths: [macosTableColumn: CGFloat] {
    var widths = macosTableSearchView.resolvedWidths(autoWidths: autoWidths, setWidths: setWidths)
    if let resize = resize {
      widths[resize.column] = resize.width
    }
    return widths
  }

  /// Columns dragged narrower than their name, which show "…" instead of their text.
  var collapsedColumns: Set<macosTableColumn> {
    var sizedByUser = Set(setWidths.keys)
    if let resize = resize {
      sizedByUser.insert(resize.column)
    }
    return macosTableSearchView.collapsedColumns(columns: columns,
                                                 widths: widths,
                                                 titleWidths: titleWidths,
                                                 sizedByUser: sizedByUser)
  }

  func resizeChanged(_ column: macosTableColumn, translation: CGFloat) {
    let startWidth = resize?.column == column ? resize!.startWidth : (widths[column] ?? macosTableSearchView.minColumnWidth)
    resize = macosTableResize(column: column,
                              startWidth: startWidth,
                              width: macosTableSearchView.resizedWidth(start: startWidth, translation: translation))
  }

  func resizeEnded() {
    if let resize = resize {
      setWidths[resize.column] = resize.width
    }
    resize = nil
  }

  var body: some View {
    let widths = widths
    let collapsedColumns = collapsedColumns

    GeometryReader { geometry in
      // Always-visible scroll bars take their width out of the visible area
      let scrollerWidth = legacyScrollers ? macosTableSearchView.legacyScrollerWidth : 0
      let visibleWidth = geometry.size.width - scrollerWidth
      let scrollsSideways = macosTableSearchView.scrollsSideways(columns: columns,
                                                                 widths: widths,
                                                                 availableWidth: visibleWidth)

      // Always both axes: once a scroll view's horizontal axis is switched off, switching it back on
      // doesn't bring back its horizontal scroller, so columns picked later couldn't be scrolled to
      ScrollView([.horizontal, .vertical], showsIndicators: true) {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
          Section {
            ForEach(rows, id: \.index) { row in
              macosTableRowView(row: row,
                                columns: columns,
                                widths: widths,
                                collapsedColumns: collapsedColumns,
                                resizingColumn: resize?.column,
                                isSelected: selectedRow == row.index,
                                onSelect: { select(row) },
                                onHideField: onHideField,
                                onFilter: onFilter)
            }

            if showsFilterNote {
              Text("Fields are being filtered by your selection. Documents will not be shown if they do not have any of the selected fields.")
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .font(.system(size: 14))
                .frame(maxWidth: geometry.size.width, alignment: .leading)
            }
          } header: {
            macosTableHeaderView(columns: columns,
                                 widths: widths,
                                 labels: labels,
                                 collapsedColumns: collapsedColumns,
                                 resizingColumn: resize?.column,
                                 visibleWidth: visibleWidth,
                                 hasSetWidths: !setWidths.isEmpty,
                                 onResize: resizeChanged(_:translation:),
                                 onResizeEnd: resizeEnded,
                                 onFit: { setWidths = macosTableSearchView.fittedWidths(columns: columns, rows: rows, labels: labels) },
                                 onReset: { setWidths = [:] },
                                 onHideField: onHideField)
          }
        }
        // A table that fits is held to the visible width, so it can't scroll sideways and the document column wraps
        .frame(width: scrollsSideways ? nil : visibleWidth, alignment: .leading)
        // Before macOS 14 the anchor below isn't available, so fill the scroll view to stop it centring the table
        .frame(minWidth: macosTableSearchView.needsFillToAlignTop ? visibleWidth : nil,
               minHeight: macosTableSearchView.needsFillToAlignTop ? geometry.size.height : nil,
               alignment: .topLeading)
      }
      // A two-way scroll view centres content smaller than itself, which also moves the pinned header
      .macosTopLeadingScrollAnchor()
    }
    .background(Color("BackgroundAlt"))
    .clipShape(.rect(cornerRadius: 5))
    .onChange(of: itemDetail.showingView) { newValue in
      if !newValue {
        selectedRow = nil
      }
    }
#if os(macOS)
    .onReceive(NotificationCenter.default.publisher(for: NSScroller.preferredScrollerStyleDidChangeNotification)) { _ in
      legacyScrollers = macosTableSearchView.usesLegacyScrollers
    }
#endif
  }
}

struct macosTableHeaderView: View {
  let columns: [macosTableColumn]
  let widths: [macosTableColumn: CGFloat]
  var labels: [String: String] = [:]
  var collapsedColumns: Set<macosTableColumn> = []
  var resizingColumn: macosTableColumn? = nil
  var visibleWidth: CGFloat = 0
  var hasSetWidths = false
  var onResize: (_ column: macosTableColumn, _ translation: CGFloat) -> Void = { _, _ in }
  var onResizeEnd: () -> Void = {}
  var onFit: () -> Void = {}
  var onReset: () -> Void = {}
  var onHideField: (macosTableColumn) -> Void = { _ in }

  @State private var hoveredColumn: macosTableColumn? = nil

  static let handleWidth: CGFloat = 8

  func isHighlighted(_ column: macosTableColumn) -> Bool {
    column == hoveredColumn || column == resizingColumn
  }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(columns, id: \.self) { column in
        headerTitle(column)
          .macosTableCell(width: widths[column],
                          compact: collapsedColumns.contains(column),
                          highlighted: isHighlighted(column))
          .contentShape(Rectangle())
          .contextMenu {
            if macosTableSearchView.canHideField(column) {
              Button("Hide field") {
                onHideField(column)
              }
              Divider()
            }
            Button("Reset column widths") {
              onReset()
            }
            .disabled(!hasSetWidths)
          }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .overlay(alignment: .bottom) {
      Rectangle().fill(Color("GridBorder")).frame(height: 1)
    }
    .overlay(alignment: .topLeading) {
      resizeHandles
    }
  }

  /// The field's name, or its data view label with the field path underneath
  @ViewBuilder
  func headerTitle(_ column: macosTableColumn) -> some View {
    if collapsedColumns.contains(column) {
      Text("…")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color("LabelBackgroundFocus"))
        .help(column.title)
        .accessibilityLabel(column.title)
    } else if let label = macosTableSearchView.label(for: column, labels: labels) {
      VStack(alignment: .leading, spacing: 1) {
        Text(label)
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(Color("LabelBackgroundFocus"))
          .lineLimit(1)
          .truncationMode(.tail)
        Text(column.title)
          .font(.system(size: 10, design: .monospaced))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
          .truncationMode(.middle)
      }
      .help("\(label)\n\(column.title)")
      .accessibilityLabel("\(label), \(column.title)")
    } else {
      Text(column.title)
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color("LabelBackgroundFocus"))
        .lineLimit(1)
        .truncationMode(.middle)
        .help(column.title)
        .accessibilityLabel(column.title)
    }
  }

  /// A grab area over each sized column's right border, plus the width label while one is dragged.
  /// They're laid over the header so they sit above the text of the next column.
  var resizeHandles: some View {
    let borders = macosTableSearchView.borderPositions(columns: columns, widths: widths)

    return ZStack(alignment: .topLeading) {
      ForEach(borders, id: \.column) { border in
        macosTableResizeHandle(onHover: { hovering in
                                 if hovering {
                                   hoveredColumn = border.column
                                 } else if hoveredColumn == border.column {
                                   hoveredColumn = nil
                                 }
                               },
                               onDrag: { onResize(border.column, $0) },
                               onDragEnd: onResizeEnd,
                               onDoubleClick: onFit)
          .frame(width: Self.handleWidth)
          .frame(maxHeight: .infinity)
          .padding(.leading, max(border.x - Self.handleWidth / 2, 0))
      }

      if let border = borders.first(where: { $0.column == resizingColumn }) {
        Text(macosTableSearchView.widthLabel(width: border.width, visibleWidth: visibleWidth))
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 3)
          .background(Color.accentColor)
          .clipShape(.rect(cornerRadius: 4))
          .fixedSize()
          .frame(maxHeight: .infinity)
          .padding(.leading, border.x + 6)
          .allowsHitTesting(false)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

/// The grab area over a column's right border: shows the resize cursor, resizes the column when dragged
/// and fits every column to its contents when double-clicked.
struct macosTableResizeHandle: View {
  let onHover: (Bool) -> Void
  let onDrag: (_ translation: CGFloat) -> Void
  let onDragEnd: () -> Void
  let onDoubleClick: () -> Void

  @State private var isHovered = false
  @State private var isDragging = false
  @State private var showsCursor = false

  /// Keeps the resize cursor until both the hover and the drag have ended,
  /// as the pointer can leave this narrow area part way through a drag.
  func updateCursor() {
#if os(macOS)
    let wanted = isHovered || isDragging
    if wanted && !showsCursor {
      NSCursor.resizeLeftRight.push()
    } else if !wanted && showsCursor {
      NSCursor.pop()
    }
    showsCursor = wanted
#endif
  }

  var body: some View {
    Color.clear
      .contentShape(Rectangle())
      .onHover { hovering in
        isHovered = hovering
        onHover(hovering)
        updateCursor()
      }
      // Global coordinates, as the handle itself moves with the border while it's dragged
      .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .global)
        .onChanged { value in
          isDragging = true
          updateCursor()
          onDrag(value.translation.width)
        }
        .onEnded { _ in
          isDragging = false
          updateCursor()
          onDragEnd()
        })
      .onTapGesture(count: 2) {
        onDoubleClick()
      }
      .onDisappear {
        isHovered = false
        isDragging = false
        updateCursor()
      }
      .help("Drag to resize the column. Double-click to fit every column to its contents.")
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
  /// A `compact` cell, in a column dragged narrower than its name, has less padding so its "…" still fits.
  /// A `highlighted` cell draws its border as the thick bar shown while its column is hovered or resized.
  func macosTableCell(width: CGFloat?, compact: Bool = false, highlighted: Bool = false) -> some View {
    self
      .padding(.horizontal, compact ? macosTableSearchView.compactCellPadding : 10)
      .padding(.vertical, 6)
      .frame(width: width, alignment: .topLeading)
      .frame(maxWidth: width == nil ? .infinity : nil, maxHeight: .infinity, alignment: .topLeading)
      .clipped()
      .overlay(alignment: .trailing) {
        Rectangle()
          .fill(highlighted ? Color.accentColor : Color("GridBorder"))
          .frame(width: highlighted ? 3 : 1)
      }
  }
}

extension macosTableSearchView {
  static let minColumnWidth: CGFloat = 60
  static let maxColumnWidth: CGFloat = 300
  /// Horizontal padding inside a cell, plus a little slack for rounding.
  static let cellPadding: CGFloat = 22
  /// Horizontal padding inside a cell of a column dragged narrower than its name.
  static let compactCellPadding: CGFloat = 4
  /// Dragging a border can make a column just wide enough for "…", or very wide.
  static let minResizedWidth: CGFloat = 30
  static let maxResizedWidth: CGFloat = 5000
  /// Double-clicking a border fits columns to their contents, but no wider than this.
  static let maxFittedWidth: CGFloat = 2000
  /// More characters than this are wider than `maxFittedWidth` even in the narrowest letters, so fitting a column
  /// doesn't need to measure the rest of a long value.
  static let fittedMeasureLength = 1000
  /// Automatic widths stop at `maxColumnWidth`, so long values are only measured this far.
  static let autoMeasureLength = 120

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

  /// Every column but the document summary stands for a field that can be hidden from the table.
  static func canHideField(_ column: macosTableColumn) -> Bool {
    column != .document
  }

  /// Hides the field behind a column, as unticking it in the sidebar does. Returns false for the document column
  /// or a field that's already hidden.
  @discardableResult
  static func hideField(_ column: macosTableColumn,
                        fields: [SquashedFieldsArray],
                        onlyVisibleFields: [SquashedFieldsArray]) -> Bool {
    let key: String
    switch column {
    case .date(let name), .field(let name):
      key = name
    case .document:
      return false
    }
    guard let field = fields.first(where: { $0.squashedString == key })
            ?? onlyVisibleFields.first(where: { $0.squashedString == key }) else {
      return false
    }
    return macosSearchFieldSheetView.setFieldVisibility(item: field,
                                                        visible: false,
                                                        fields: fields,
                                                        onlyVisibleFields: onlyVisibleFields)
  }

  /// The rows to show, in their original order, each with a summary of its fields other than the date.
  static func visibleRows(flatArray: [OrderedDictionary<String, Any>],
                          refs: [DocumentRef?] = [],
                          dateField: SquashedFieldsArray?,
                          filteredFields: [SquashedFieldsArray],
                          showDateHeader: Bool) -> [macosTableRow] {
    flatArray.indices.compactMap { index in
      let item = flatArray[index]
      var itemWithoutDate = item
      if let dateKey = dateField?.squashedString {
        itemWithoutDate.removeValue(forKey: dateKey)
      }
      let summary = ElasticDocumentBuilder.exportFlatValues(input: itemWithoutDate, filteredFields: filteredFields)
      let show = shouldDisplayRow(hasBodyContent: !summary.isEmpty,
                                  showDateHeader: showDateHeader,
                                  hasDateValue: !dateValue(from: item, dateField: dateField).isEmpty,
                                  isBodyFiltered: !filteredFields.isEmpty)
      let ref = index < refs.count ? refs[index] : nil
      return show ? macosTableRow(index: index, item: item, summary: summary, ref: ref) : nil
    }
  }

  static func layoutKey(renderedObjects: RenderObject,
                        fieldsVersion: UUID,
                        filteredFields: [SquashedFieldsArray],
                        showDateHeader: Bool,
                        labels: [String: String] = [:]) -> macosTableLayoutKey {
    macosTableLayoutKey(resultsID: renderedObjects.id,
                        fieldsVersion: fieldsVersion,
                        dateKey: renderedObjects.dateField?.squashedString,
                        showDateHeader: showDateHeader,
                        fieldKeys: Set(filteredFields.map { $0.squashedString }),
                        labels: labels)
  }

  /// Builds the rows and measures every cell and column name the width cache hasn't measured already.
  static func layout(flatArray: [OrderedDictionary<String, Any>],
                     refs: [DocumentRef?] = [],
                     dateField: SquashedFieldsArray?,
                     filteredFields: [SquashedFieldsArray],
                     showDateHeader: Bool,
                     columns: [macosTableColumn],
                     labels: [String: String] = [:],
                     widthCache: macosTableWidthCache) -> macosTableLayout {
    let rows = visibleRows(flatArray: flatArray,
                           refs: refs,
                           dateField: dateField,
                           filteredFields: filteredFields,
                           showDateHeader: showDateHeader)
    return macosTableLayout(rows: rows,
                            autoWidths: columnWidths(columns: columns, rows: rows, labels: labels, cache: widthCache),
                            titleWidths: titleWidths(columns: columns, labels: labels, cache: widthCache))
  }

  static func dateValue(from item: OrderedDictionary<String, Any>, dateField: SquashedFieldsArray?) -> String {
    guard let dateField = dateField else { return "" }
    return (item[dateField.squashedString] as? [String])?.first ?? ""
  }

  /// Determines whether a document row should be shown in the search results.
  /// When body fields are filtered (`isBodyFiltered == true`), documents must contain at least one of the selected
  /// body fields (`hasBodyContent == true`), so no row is shown with only a date.
  /// When body fields are unfiltered (`isBodyFiltered == false`), documents are shown if they have body content
  /// or an active date column with a valid date.
  static func shouldDisplayRow(hasBodyContent: Bool,
                               showDateHeader: Bool,
                               hasDateValue: Bool,
                               isBodyFiltered: Bool) -> Bool {
    isBodyFiltered
      ? hasBodyContent
      : (hasBodyContent || (showDateHeader && hasDateValue))
  }

  /// The non-blank values of a field. A missing key, `[""]` and whitespace-only values all count as missing,
  /// matching what the document summary skips.
  static func values(for key: String, in item: OrderedDictionary<String, Any>) -> [String] {
    guard let values = item[key] as? [String] else { return [] }
    return values.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
  }

  /// The text of a field cell: every value joined into one line, or nil when the field is missing.
  static func cellText(for key: String, in item: OrderedDictionary<String, Any>) -> String? {
    let found = values(for: key, in: item)
    return found.isEmpty ? nil : found.joined(separator: ", ")
  }

  /// The date cell's text, formatted with `DateTools.buildDateLarge`, falling back to the raw value.
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

  /// A cell's value as stored, for copying: the date unformatted, and a field's values joined as in its cell.
  static func rawText(for column: macosTableColumn, in item: OrderedDictionary<String, Any>) -> String? {
    switch column {
    case .date(let key):
      return values(for: key, in: item).first
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
                           labels: [String: String] = [:],
                           measure: (_ text: String, _ bold: Bool) -> CGFloat = macosTableSearchView.measureText(_:bold:)) -> [macosTableColumn: CGFloat] {
    fit(columns: columns,
        maxWidth: maxColumnWidth,
        headerWidth: { headerWidth($0, labels: labels, measure: measure) },
        widestCell: { widestCell($0, rows: rows, measuredLength: autoMeasureLength, measure: measure) })
  }

  /// The same widths as `columnWidths(columns:rows:labels:measure:)`, but only cells and headers the cache
  /// hasn't seen are measured.
  static func columnWidths(columns: [macosTableColumn],
                           rows: [macosTableRow],
                           labels: [String: String] = [:],
                           cache: macosTableWidthCache,
                           measure: (_ text: String, _ bold: Bool) -> CGFloat = macosTableSearchView.measureText(_:bold:)) -> [macosTableColumn: CGFloat] {
    fit(columns: columns,
        maxWidth: maxColumnWidth,
        headerWidth: { cache.headerWidth($0, labels: labels, measure: measure) },
        widestCell: { cache.widestCell($0, rows: rows, measure: measure) })
  }

  /// Sizes each field column to its full header and values, for a double-click on a column border.
  /// Unlike the automatic widths these go past `maxColumnWidth`, up to `maxFittedWidth`.
  static func fittedWidths(columns: [macosTableColumn],
                           rows: [macosTableRow],
                           labels: [String: String] = [:],
                           measure: (_ text: String, _ bold: Bool) -> CGFloat = macosTableSearchView.measureText(_:bold:)) -> [macosTableColumn: CGFloat] {
    fit(columns: columns,
        maxWidth: maxFittedWidth,
        headerWidth: { headerWidth($0, labels: labels, measure: measure) },
        widestCell: { widestCell($0, rows: rows, measuredLength: fittedMeasureLength, measure: measure) })
  }

  private static func fit(columns: [macosTableColumn],
                          maxWidth: CGFloat,
                          headerWidth: (macosTableColumn) -> CGFloat,
                          widestCell: (macosTableColumn) -> CGFloat) -> [macosTableColumn: CGFloat] {
    var widths = [macosTableColumn: CGFloat]()
    for column in columns where column != .document {
      let widest = max(headerWidth(column), widestCell(column))
      widths[column] = min(max(widest + cellPadding, minColumnWidth), maxWidth)
    }
    return widths
  }

  /// The width of the cell's text, measured up to `measuredLength` characters, or 0 when the field is missing.
  static func cellWidth(_ column: macosTableColumn,
                        in row: macosTableRow,
                        measuredLength: Int,
                        measure: (_ text: String, _ bold: Bool) -> CGFloat) -> CGFloat {
    guard let value = text(for: column, in: row.item) else { return 0 }
    return measure(String(value.prefix(measuredLength)), false)
  }

  static func widestCell(_ column: macosTableColumn,
                         rows: [macosTableRow],
                         measuredLength: Int,
                         measure: (_ text: String, _ bold: Bool) -> CGFloat) -> CGFloat {
    rows.reduce(0) { max($0, cellWidth(column, in: $1, measuredLength: measuredLength, measure: measure)) }
  }

  /// The width of each sized column's name, which decides when a narrow column shows "…".
  static func titleWidths(columns: [macosTableColumn],
                          labels: [String: String] = [:],
                          measure: (_ text: String, _ bold: Bool) -> CGFloat = macosTableSearchView.measureText(_:bold:)) -> [macosTableColumn: CGFloat] {
    titleWidths(columns: columns) { headerWidth($0, labels: labels, measure: measure) }
  }

  /// The same widths as `titleWidths(columns:labels:measure:)`, measuring only headers the cache hasn't seen.
  static func titleWidths(columns: [macosTableColumn],
                          labels: [String: String] = [:],
                          cache: macosTableWidthCache,
                          measure: (_ text: String, _ bold: Bool) -> CGFloat = macosTableSearchView.measureText(_:bold:)) -> [macosTableColumn: CGFloat] {
    titleWidths(columns: columns) { cache.headerWidth($0, labels: labels, measure: measure) }
  }

  private static func titleWidths(columns: [macosTableColumn],
                                  headerWidth: (macosTableColumn) -> CGFloat) -> [macosTableColumn: CGFloat] {
    var widths = [macosTableColumn: CGFloat]()
    for column in columns where column != .document {
      widths[column] = headerWidth(column)
    }
    return widths
  }

  /// The column's data view label, if its field has one
  static func label(for column: macosTableColumn, labels: [String: String]) -> String? {
    switch column {
    case .date(let key), .field(let key):
      return DataViewSelection.label(for: key, labels: labels)
    case .document:
      return nil
    }
  }

  /// A labelled header is as wide as the wider of its label and its field path, which sits underneath in smaller text
  static func headerWidth(_ column: macosTableColumn,
                          labels: [String: String],
                          measure: (_ text: String, _ bold: Bool) -> CGFloat) -> CGFloat {
    guard let label = label(for: column, labels: labels) else {
      return measure(column.title, true)
    }
    return max(measure(label, true), measure(column.title, false))
  }

  /// The width each column is drawn at: one set by dragging or fitting wins over the automatic width.
  /// Set widths of columns no longer shown, and of the document column, are left out.
  static func resolvedWidths(autoWidths: [macosTableColumn: CGFloat],
                             setWidths: [macosTableColumn: CGFloat]) -> [macosTableColumn: CGFloat] {
    autoWidths.merging(setWidths.filter { autoWidths[$0.key] != nil }) { _, set in set }
  }

  /// A dragged column's width: its width when the drag started plus how far the pointer has moved, within the limits.
  static func resizedWidth(start: CGFloat, translation: CGFloat) -> CGFloat {
    min(max(start + translation, minResizedWidth), maxResizedWidth)
  }

  /// A column shows "…" when someone has sized it narrower than its name.
  /// Automatic widths never collapse a column, so a long name is cut off in the middle as before.
  static func isCollapsed(width: CGFloat, titleWidth: CGFloat) -> Bool {
    width < titleWidth + cellPadding
  }

  static func collapsedColumns(columns: [macosTableColumn],
                               widths: [macosTableColumn: CGFloat],
                               titleWidths: [macosTableColumn: CGFloat],
                               sizedByUser: Set<macosTableColumn>) -> Set<macosTableColumn> {
    Set(columns.filter { column in
      guard sizedByUser.contains(column), let width = widths[column], let titleWidth = titleWidths[column] else {
        return false
      }
      return isCollapsed(width: width, titleWidth: titleWidth)
    })
  }

  struct Border: Hashable {
    let column: macosTableColumn
    let x: CGFloat
    let width: CGFloat
  }

  /// Where each sized column's right border sits, from the table's leading edge.
  /// The document column fills the rest of the row, so it has no border to drag.
  static func borderPositions(columns: [macosTableColumn], widths: [macosTableColumn: CGFloat]) -> [Border] {
    var borders = [Border]()
    var x: CGFloat = 0
    for column in columns {
      guard let width = widths[column] else { break }
      x += width
      borders.append(Border(column: column, x: x, width: width))
    }
    return borders
  }

  /// The label shown while a border is dragged: the column's width as a share of the visible table.
  static func widthLabel(width: CGFloat, visibleWidth: CGFloat) -> String {
    guard visibleWidth > 0 else { return "Cell Width" }
    return "Cell Width: \(Int((width / visibleWidth * 100).rounded()))%"
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

  // Made once, as the table measures every cell with them
#if os(macOS)
  private static let regularTextAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12, weight: .regular)]
  private static let boldTextAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12, weight: .semibold)]
#else
  private static let regularTextAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .regular)]
  private static let boldTextAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
#endif

  static func measureText(_ text: String, bold: Bool) -> CGFloat {
    ceil((text as NSString).size(withAttributes: bold ? boldTextAttributes : regularTextAttributes).width)
  }
}
