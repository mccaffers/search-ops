// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import OrderedCollections

@testable import Search_Ops

final class macosTableSearchViewTests: XCTestCase {

  func field(_ name: String, visible: Bool = true) -> SquashedFieldsArray {
    let field = SquashedFieldsArray(squashedString: name, fieldParts: name.components(separatedBy: "."))
    field.visible = visible
    return field
  }

  func row(_ item: OrderedDictionary<String, Any>, index: Int = 0) -> macosTableRow {
    macosTableRow(index: index, item: item, summary: [])
  }

  // MARK: - Filter buttons

  func rowView(_ item: OrderedDictionary<String, Any>,
               collapsed: Set<macosTableColumn> = [],
               filterable: Bool = true) -> macosTableRowView {
    macosTableRowView(row: row(item),
                      columns: [],
                      widths: [:],
                      collapsedColumns: collapsed,
                      isSelected: false,
                      onSelect: {},
                      onFilter: filterable ? { _, _, _ in } : nil)
  }

  func testFieldCellsWithOneValueCanBeFiltered() {
    let view = rowView(["cpu1": ["0"], "host.name": ["live-trading"]])
    XCTAssertEqual(view.filterValue(for: .field("cpu1")), "0")
    XCTAssertEqual(view.filterValue(for: .field("host.name")), "live-trading")
  }

  func testDateMissingAndMultiValueCellsCantBeFiltered() {
    let view = rowView(["@timestamp": ["2026-10-09T22:49:01Z"], "tags": ["a", "b"]])
    XCTAssertNil(view.filterValue(for: .date("@timestamp")))
    XCTAssertNil(view.filterValue(for: .field("tags")))
    XCTAssertNil(view.filterValue(for: .field("missing")))
    XCTAssertNil(view.filterValue(for: .document))
  }

  func testCollapsedCellsAndTablesWithoutFilteringHaveNoButtons() {
    XCTAssertNil(rowView(["cpu1": ["0"]], collapsed: [.field("cpu1")]).filterValue(for: .field("cpu1")))
    XCTAssertNil(rowView(["cpu1": ["0"]], filterable: false).filterValue(for: .field("cpu1")))
  }

  // MARK: - Copy button

  func testCopyValueIsTheRawValue() {
    let view = rowView(["@timestamp": ["2026-10-09T22:49:01Z"], "cpu1": ["0"], "tags": ["a", "b"]])
    XCTAssertEqual(view.copyValue(for: .date("@timestamp")), "2026-10-09T22:49:01Z")
    XCTAssertEqual(view.copyValue(for: .field("cpu1")), "0")
    XCTAssertEqual(view.copyValue(for: .field("tags")), "a, b")
  }

  func testDateCellCopiesItsStoredValueNotItsText() {
    let item: OrderedDictionary<String, Any> = ["@timestamp": ["2026-10-09T22:49:01Z"]]
    XCTAssertNotEqual(macosTableSearchView.text(for: .date("@timestamp"), in: item), "2026-10-09T22:49:01Z")
    XCTAssertEqual(macosTableSearchView.rawText(for: .date("@timestamp"), in: item), "2026-10-09T22:49:01Z")
  }

  func testMissingCollapsedAndDocumentCellsHaveNoCopyButton() {
    let view = rowView(["cpu1": ["0"], "blank": [" "]], collapsed: [.field("cpu1")])
    XCTAssertNil(view.copyValue(for: .field("cpu1")))
    XCTAssertNil(view.copyValue(for: .field("blank")))
    XCTAssertNil(view.copyValue(for: .field("missing")))
    XCTAssertNil(view.copyValue(for: .date("missing")))
    XCTAssertNil(view.copyValue(for: .document))
  }

  func testTablesWithoutFilteringCanStillCopy() {
    XCTAssertEqual(rowView(["cpu1": ["0"]], filterable: false).copyValue(for: .field("cpu1")), "0")
  }

  func testNoResultsMessagePointsAtFiltersWhenAnyAreOn() {
    XCTAssertEqual(macosSearchResultsView.noResultsMessage(activeFilterCount: 0),
                   "No results. Try adjusting the query string or date range.")
    XCTAssertEqual(macosSearchResultsView.noResultsMessage(activeFilterCount: 1),
                   "No results. Try disabling or removing the filter, or adjusting the query string or date range.")
    XCTAssertEqual(macosSearchResultsView.noResultsMessage(activeFilterCount: 11),
                   "No results. Try disabling or removing a filter, or adjusting the query string or date range.")
  }

  // MARK: - Columns

  func testColumnsPutDateFirstThenPickedFields() {
    let columns = macosTableSearchView.columns(dateField: field("@timestamp"),
                                               showDateHeader: true,
                                               filteredFields: [field("user.name"), field("status")])
    XCTAssertEqual(columns, [.date("@timestamp"), .field("user.name"), .field("status")])
  }

  func testColumnsFallBackToDocumentSummaryWhenNoFieldsPicked() {
    let columns = macosTableSearchView.columns(dateField: field("@timestamp"),
                                               showDateHeader: true,
                                               filteredFields: [])
    XCTAssertEqual(columns, [.date("@timestamp"), .document])
  }

  func testColumnsLeaveOutDateWhenDateHeaderHidden() {
    XCTAssertEqual(macosTableSearchView.columns(dateField: field("@timestamp"),
                                                showDateHeader: false,
                                                filteredFields: [field("status")]),
                   [.field("status")])
    XCTAssertEqual(macosTableSearchView.columns(dateField: nil,
                                                showDateHeader: true,
                                                filteredFields: []),
                   [.document])
  }

  // MARK: - Hiding fields

  func testHideFieldHidesItInFieldsAndVisibleFields() {
    let status = field("status")
    let shown = field("status")
    let other = field("user.name")
    let fields = [status, other]
    let onlyVisible = [shown]

    XCTAssertTrue(macosTableSearchView.hideField(.field("status"), fields: fields, onlyVisibleFields: onlyVisible))
    XCTAssertFalse(status.visible)
    XCTAssertFalse(shown.visible)
    XCTAssertTrue(other.visible)
  }

  func testHideFieldFindsAFieldOnlyInVisibleFields() {
    let shown = field("extra")
    XCTAssertTrue(macosTableSearchView.hideField(.field("extra"), fields: [], onlyVisibleFields: [shown]))
    XCTAssertFalse(shown.visible)
  }

  func testHideFieldHidesTheDateField() {
    let date = field("@timestamp")
    let status = field("status")

    XCTAssertTrue(macosTableSearchView.hideField(.date("@timestamp"), fields: [date, status], onlyVisibleFields: []))
    XCTAssertFalse(date.visible)
    XCTAssertTrue(status.visible)
  }

  func testHideFieldLeavesDocumentColumnAndHiddenFieldsAlone() {
    let status = field("status")
    let hidden = field("user.name", visible: false)

    XCTAssertFalse(macosTableSearchView.canHideField(.document))
    XCTAssertTrue(macosTableSearchView.canHideField(.field("status")))
    XCTAssertTrue(macosTableSearchView.canHideField(.date("@timestamp")))
    XCTAssertFalse(macosTableSearchView.hideField(.document, fields: [status, hidden], onlyVisibleFields: []))
    XCTAssertFalse(macosTableSearchView.hideField(.field("user.name"), fields: [status, hidden], onlyVisibleFields: []))
    XCTAssertFalse(macosTableSearchView.hideField(.field("missing"), fields: [status, hidden], onlyVisibleFields: []))
    XCTAssertTrue(status.visible)
    XCTAssertFalse(hidden.visible)
  }

  // MARK: - Cells

  func testCellJoinsMultipleAndRepeatedValuesIntoOneCell() {
    let item: OrderedDictionary<String, Any> = ["tags": ["a", "b", "c"], "codes": ["0", "0"]]
    XCTAssertEqual(macosTableSearchView.cellText(for: "tags", in: item), "a, b, c")
    XCTAssertEqual(macosTableSearchView.cellText(for: "codes", in: item), "0, 0")
  }

  func testCellTreatsMissingAndBlankValuesAsMissing() {
    let item: OrderedDictionary<String, Any> = ["empty": [""], "spaces": ["  "], "mixed": ["", "x", " "]]
    XCTAssertNil(macosTableSearchView.cellText(for: "empty", in: item))
    XCTAssertNil(macosTableSearchView.cellText(for: "spaces", in: item))
    XCTAssertNil(macosTableSearchView.cellText(for: "absent", in: item))
    XCTAssertEqual(macosTableSearchView.cellText(for: "mixed", in: item), "x")
  }

  func testDateCellIsFormattedAndFallsBackToRawValue() {
    let item: OrderedDictionary<String, Any> = [
      "iso": ["2026-09-20T12:00:00"],
      "odd": ["not a date"]
    ]
    XCTAssertEqual(macosTableSearchView.dateText(for: "iso", in: item),
                   DateTools.buildDateLarge(input: "2026-09-20T12:00:00"))
    XCTAssertNotEqual(macosTableSearchView.dateText(for: "iso", in: item), "2026-09-20T12:00:00")
    XCTAssertEqual(macosTableSearchView.dateText(for: "odd", in: item), "not a date")
    XCTAssertNil(macosTableSearchView.dateText(for: "absent", in: item))
  }

  // MARK: - Column widths

  func testColumnWidthsFitWidestValueWithinLimits() {
    let columns: [macosTableColumn] = [.field("short"), .field("long"), .field("medium"), .document]
    let rows = [
      row(["short": ["a"], "long": [String(repeating: "x", count: 500)], "medium": [String(repeating: "m", count: 50)]])
    ]
    // Three points per character keeps the arithmetic obvious
    let widths = macosTableSearchView.columnWidths(columns: columns, rows: rows) { text, _ in
      CGFloat(text.count * 3)
    }
    XCTAssertEqual(widths[.field("short")], macosTableSearchView.minColumnWidth)
    XCTAssertEqual(widths[.field("long")], macosTableSearchView.maxColumnWidth)
    XCTAssertEqual(widths[.field("medium")], 150 + macosTableSearchView.cellPadding)
    XCTAssertNil(widths[.document], "The document column fills the rest of the row")
  }

  func testColumnWidthsCountTheHeader() {
    let header = "a_really_long_field_name_for_the_header"
    let widths = macosTableSearchView.columnWidths(columns: [.field(header)],
                                                   rows: [row([header: ["1"]])]) { text, _ in
      CGFloat(text.count * 2)
    }
    XCTAssertEqual(widths[.field(header)], CGFloat(header.count * 2) + macosTableSearchView.cellPadding)
  }

  func testTableScrollsSidewaysOnlyWhenColumnsDoNotFit() {
    let columns: [macosTableColumn] = [.date("@timestamp"), .field("status")]
    let widths: [macosTableColumn: CGFloat] = [.date("@timestamp"): 150, .field("status"): 100]
    XCTAssertFalse(macosTableSearchView.scrollsSideways(columns: columns, widths: widths, availableWidth: 250))
    XCTAssertTrue(macosTableSearchView.scrollsSideways(columns: columns, widths: widths, availableWidth: 249))
  }

  func testDocumentColumnNeverScrollsSideways() {
    let columns: [macosTableColumn] = [.date("@timestamp"), .document]
    let widths: [macosTableColumn: CGFloat] = [.date("@timestamp"): 150]
    XCTAssertFalse(macosTableSearchView.scrollsSideways(columns: columns, widths: widths, availableWidth: 100))
  }

  // MARK: - Resizing columns

  func testSetWidthWinsOverAutomaticWidth() {
    let auto: [macosTableColumn: CGFloat] = [.date("@timestamp"): 150, .field("message"): 300]
    let widths = macosTableSearchView.resolvedWidths(autoWidths: auto, setWidths: [.field("message"): 42])
    XCTAssertEqual(widths, [.date("@timestamp"): 150, .field("message"): 42])
  }

  func testSetWidthsOfDocumentAndHiddenColumnsAreIgnored() {
    let auto: [macosTableColumn: CGFloat] = [.field("message"): 300]
    let widths = macosTableSearchView.resolvedWidths(autoWidths: auto,
                                                     setWidths: [.document: 500, .field("removed"): 80])
    XCTAssertEqual(widths, [.field("message"): 300])
    XCTAssertNil(widths[.document], "The document column always fills the rest of the row")
  }

  func testResizedWidthFollowsDragWithinLimits() {
    XCTAssertEqual(macosTableSearchView.resizedWidth(start: 200, translation: 55), 255)
    XCTAssertEqual(macosTableSearchView.resizedWidth(start: 200, translation: -60), 140)
    XCTAssertEqual(macosTableSearchView.resizedWidth(start: 200, translation: -500), macosTableSearchView.minResizedWidth)
    XCTAssertEqual(macosTableSearchView.resizedWidth(start: 200, translation: 9000), macosTableSearchView.maxResizedWidth)
    XCTAssertGreaterThan(macosTableSearchView.maxResizedWidth, macosTableSearchView.maxFittedWidth,
                         "A column can be dragged wider than a double-click fits it")
  }

  func testColumnCollapsesOnlyWhenNarrowerThanItsName() {
    let titleWidth: CGFloat = 50
    XCTAssertFalse(macosTableSearchView.isCollapsed(width: titleWidth + macosTableSearchView.cellPadding, titleWidth: titleWidth))
    XCTAssertTrue(macosTableSearchView.isCollapsed(width: titleWidth + macosTableSearchView.cellPadding - 1, titleWidth: titleWidth))
  }

  func testOnlyColumnsSizedByUserCollapse() {
    let columns: [macosTableColumn] = [.field("a_long_field_name"), .field("dragged"), .document]
    let widths: [macosTableColumn: CGFloat] = [.field("a_long_field_name"): 300, .field("dragged"): 30]
    let titleWidths: [macosTableColumn: CGFloat] = [.field("a_long_field_name"): 400, .field("dragged"): 40]
    let collapsed = macosTableSearchView.collapsedColumns(columns: columns,
                                                          widths: widths,
                                                          titleWidths: titleWidths,
                                                          sizedByUser: [.field("dragged")])
    XCTAssertEqual(collapsed, [.field("dragged")],
                   "A long name at its automatic width is cut off in the middle rather than collapsed")
  }

  func testFittedWidthsMeasureFullValuesUpToTheFitLimit() {
    let columns: [macosTableColumn] = [.field("short"), .field("medium"), .field("huge"), .document]
    let rows = [
      row(["short": ["a"], "medium": [String(repeating: "m", count: 200)], "huge": [String(repeating: "x", count: 5000)]])
    ]
    let widths = macosTableSearchView.fittedWidths(columns: columns, rows: rows) { text, _ in
      CGFloat(text.count * 3)
    }
    XCTAssertEqual(widths[.field("short")], macosTableSearchView.minColumnWidth)
    XCTAssertEqual(widths[.field("medium")], 600 + macosTableSearchView.cellPadding,
                   "Fitting measures past the automatic 120 characters and goes past the automatic maximum")
    XCTAssertEqual(widths[.field("huge")], macosTableSearchView.maxFittedWidth)
    XCTAssertNil(widths[.document])
  }

  func testFittedWidthsCoverEverySizedColumn() {
    let columns: [macosTableColumn] = [.date("@timestamp"), .field("message"), .field("status")]
    let rows = [row(["@timestamp": ["2026-09-20T12:00:00"], "message": ["hello"]])]
    let widths = macosTableSearchView.fittedWidths(columns: columns, rows: rows)
    XCTAssertEqual(Set(widths.keys), Set(columns))
  }

  func testTitleWidthsLeaveOutDocumentColumn() {
    let widths = macosTableSearchView.titleWidths(columns: [.date("@timestamp"), .document]) { text, _ in
      CGFloat(text.count)
    }
    XCTAssertEqual(widths, [.date("@timestamp"): 10])
  }

  // MARK: - Data view labels

  func testLabelledTitleIsAsWideAsItsLabelOrPath() {
    // Bold text counts double, so the label wins for a short path and the path for a long one
    let measure: (String, Bool) -> CGFloat = { text, bold in CGFloat(text.count) * (bold ? 2 : 1) }
    let columns: [macosTableColumn] = [.field("FILL_PRICE"), .field("execution.slippagePointsAverage"), .field("SYMBOL")]
    let labels = ["FILL_PRICE": "Fill price", "execution.slippagePointsAverage": "Slip"]

    let widths = macosTableSearchView.titleWidths(columns: columns, labels: labels, measure: measure)
    XCTAssertEqual(widths[.field("FILL_PRICE")], 20)
    XCTAssertEqual(widths[.field("execution.slippagePointsAverage")], 31)
    // Unlabelled columns measure their bold path, as before
    XCTAssertEqual(widths[.field("SYMBOL")], 12)
  }

  func testColumnWidthsMakeRoomForALongLabel() {
    let measure: (String, Bool) -> CGFloat = { text, _ in CGFloat(text.count * 10) }
    let rows = [macosTableRow(index: 0, item: ["a": ["1"]], summary: [])]
    let label = String(repeating: "x", count: 12)

    let unlabelled = macosTableSearchView.columnWidths(columns: [.field("a")], rows: rows, measure: measure)
    let labelled = macosTableSearchView.columnWidths(columns: [.field("a")], rows: rows, labels: ["a": label], measure: measure)
    XCTAssertEqual(unlabelled[.field("a")], macosTableSearchView.minColumnWidth)
    XCTAssertEqual(labelled[.field("a")], 120 + macosTableSearchView.cellPadding)
  }

  func testOnlyFieldAndDateColumnsHaveLabels() {
    let labels = ["@timestamp": "Time", "a": "  "]
    XCTAssertEqual(macosTableSearchView.label(for: .date("@timestamp"), labels: labels), "Time")
    XCTAssertNil(macosTableSearchView.label(for: .field("a"), labels: labels))
    XCTAssertNil(macosTableSearchView.label(for: .document, labels: labels))
  }

  func testSetWidthsScrollTableSideways() {
    let columns: [macosTableColumn] = [.field("message"), .field("status")]
    let auto: [macosTableColumn: CGFloat] = [.field("message"): 300, .field("status"): 60]
    XCTAssertFalse(macosTableSearchView.scrollsSideways(columns: columns, widths: auto, availableWidth: 800))
    let widths = macosTableSearchView.resolvedWidths(autoWidths: auto, setWidths: [.field("message"): 2000])
    XCTAssertTrue(macosTableSearchView.scrollsSideways(columns: columns, widths: widths, availableWidth: 800))
  }

  func testSetWidthMovesWithReorderedColumn() {
    let auto: [macosTableColumn: CGFloat] = [.field("message"): 300, .field("status"): 60]
    let widths = macosTableSearchView.resolvedWidths(autoWidths: auto, setWidths: [.field("message"): 120])

    let before = macosTableSearchView.borderPositions(columns: [.field("message"), .field("status")], widths: widths)
    XCTAssertEqual(before.map(\.x), [120, 180])

    let after = macosTableSearchView.borderPositions(columns: [.field("status"), .field("message")], widths: widths)
    XCTAssertEqual(after.map(\.column), [.field("status"), .field("message")])
    XCTAssertEqual(after.map(\.width), [60, 120])
    XCTAssertEqual(after.map(\.x), [60, 180])
  }

  func testBordersStopAtDocumentColumn() {
    let borders = macosTableSearchView.borderPositions(columns: [.date("@timestamp"), .document],
                                                       widths: [.date("@timestamp"): 150])
    XCTAssertEqual(borders.map(\.column), [.date("@timestamp")])
  }

  func testWidthLabelShowsShareOfVisibleTable() {
    XCTAssertEqual(macosTableSearchView.widthLabel(width: 350, visibleWidth: 500), "Cell Width: 70%")
    XCTAssertEqual(macosTableSearchView.widthLabel(width: 1, visibleWidth: 3), "Cell Width: 33%")
    XCTAssertEqual(macosTableSearchView.widthLabel(width: 100, visibleWidth: 0), "Cell Width")
  }

  // MARK: - Rows

  func testVisibleRowsFollowFieldsAndDateColumn() {
    let dateField = field("@timestamp")
    let flat: [OrderedDictionary<String, Any>] = [
      ["@timestamp": ["2026-09-20T12:00:00"], "message": ["hello"]],
      ["@timestamp": ["2026-09-20T12:01:00"], "status": ["200"]],
      ["@timestamp": ["2026-09-20T12:02:00"], "message": [""]],
      ["message": ["   "]],
      ["@timestamp": ["2026-09-20T12:03:00"], "message": ["bye"], "status": ["500"]]
    ]

    // Unfiltered rows show with body content, or with only a date while the date column is on.
    // Filtered rows show only when they have a non-blank picked field.
    let cases: [(filteredFields: [SquashedFieldsArray], showDateHeader: Bool, expected: [Int])] = [
      ([], true, [0, 1, 2, 4]),
      ([], false, [0, 1, 4]),
      ([field("message")], true, [0, 4]),
      ([field("message")], false, [0, 4]),
      ([field("message"), field("status")], true, [0, 1, 4]),
      ([field("message"), field("status")], false, [0, 1, 4])
    ]

    for (filteredFields, showDateHeader, expected) in cases {
      let rows = macosTableSearchView.visibleRows(flatArray: flat,
                                                  dateField: dateField,
                                                  filteredFields: filteredFields,
                                                  showDateHeader: showDateHeader)
      XCTAssertEqual(rows.map(\.index), expected,
                     "fields: \(filteredFields.map(\.squashedString)), date header: \(showDateHeader)")
    }
  }

  func testVisibleRowsHideDocumentsWithoutPickedFields() {
    let flat: [OrderedDictionary<String, Any>] = [
      ["@timestamp": ["2026-09-20T12:00:00"], "message": ["hello"]],
      ["@timestamp": ["2026-09-20T12:01:00"], "status": ["200"]],
      ["@timestamp": ["2026-09-20T12:02:00"], "message": [""]]
    ]
    let rows = macosTableSearchView.visibleRows(flatArray: flat,
                                                dateField: field("@timestamp"),
                                                filteredFields: [field("message")],
                                                showDateHeader: true)
    XCTAssertEqual(rows.map(\.index), [0])
    XCTAssertEqual(rows.first?.summary.map(\.value), ["message", "hello"])
  }

  func testVisibleRowsKeepFlatRowForDetailPanel() {
    let flat: [OrderedDictionary<String, Any>] = [["user.name": ["ryan"], "@timestamp": ["2026-09-20T12:00:00"]]]
    let rows = macosTableSearchView.visibleRows(flatArray: flat,
                                                dateField: field("@timestamp"),
                                                filteredFields: [],
                                                showDateHeader: true)
    XCTAssertEqual(rows.first?.item.keys.elements, ["user.name", "@timestamp"])
  }

  func testVisibleRowsKeepEachDocumentsRefByItsOriginalPosition() {
    let flat: [OrderedDictionary<String, Any>] = [
      ["message": ["hello"]],
      ["status": ["200"]],
      ["message": ["bye"]]
    ]
    let refs: [DocumentRef?] = [DocumentRef(index: "logs-1", id: "a"), DocumentRef(index: "logs-1", id: "b"), nil]
    let rows = macosTableSearchView.visibleRows(flatArray: flat,
                                                refs: refs,
                                                dateField: nil,
                                                filteredFields: [field("message")],
                                                showDateHeader: false)
    XCTAssertEqual(rows.map(\.index), [0, 2])
    XCTAssertEqual(rows.map(\.ref), [DocumentRef(index: "logs-1", id: "a"), nil])
  }

  func testVisibleRowsWithoutRefsHaveNone() {
    let rows = macosTableSearchView.visibleRows(flatArray: [["message": ["hello"]]],
                                                dateField: nil,
                                                filteredFields: [],
                                                showDateHeader: false)
    XCTAssertNil(rows.first?.ref)
  }

  // MARK: - Saved column widths

  func testColumnsKeepTheirKindInASavedSearch() {
    let columns: [macosTableColumn] = [.date("date"), .field("dayClose"), .field("date:odd"), .document]
    for column in columns {
      XCTAssertEqual(macosTableColumn(savedKey: column.savedKey), column)
    }
    XCTAssertEqual(macosTableColumn.field("dayClose").savedKey, "field:dayClose")
    XCTAssertNil(macosTableColumn(savedKey: "dayClose"))
  }

  func testSavedWidthsRoundTripAndSkipWhatCantBeRead() {
    let widths: [macosTableColumn: CGFloat] = [.date("date"): 512.5, .field("dayClose"): 82]
    let saved = macosTableColumn.savedWidths(widths)
    XCTAssertEqual(saved, ["date:date": 512.5, "field:dayClose": 82])

    var withJunk = saved
    withJunk["mystery"] = 100
    withJunk["field:zero"] = 0
    XCTAssertEqual(macosTableColumn.widths(fromSaved: withJunk), widths)
  }

  // MARK: - Layout cache

  func results(dateField: SquashedFieldsArray? = nil) -> RenderObject {
    RenderObject(headers: [], results: [], flat: [["status": ["200"]]], dateField: dateField)
  }

  let fieldsVersion = UUID()

  func layoutKey(_ rendered: RenderObject,
                 fields: [SquashedFieldsArray],
                 showDateHeader: Bool = true,
                 fieldsVersion: UUID? = nil,
                 labels: [String: String] = [:]) -> macosTableLayoutKey {
    macosTableSearchView.layoutKey(renderedObjects: rendered,
                                   fieldsVersion: fieldsVersion ?? self.fieldsVersion,
                                   filteredFields: fields,
                                   showDateHeader: showDateHeader,
                                   labels: labels)
  }

  func testLayoutKeyChangesWithLabels() {
    let rendered = results()
    let key = layoutKey(rendered, fields: [field("a")])
    XCTAssertNotEqual(key, layoutKey(rendered, fields: [field("a")], labels: ["a": "Alpha"]))
    XCTAssertEqual(layoutKey(rendered, fields: [field("a")], labels: ["a": "Alpha"]),
                   layoutKey(rendered, fields: [field("a")], labels: ["a": "Alpha"]))
  }

  func testLayoutKeyIgnoresFieldOrder() {
    let rendered = results()
    XCTAssertEqual(layoutKey(rendered, fields: [field("a"), field("b")]),
                   layoutKey(rendered, fields: [field("b"), field("a")]))
  }

  func testLayoutKeyChangesWithResultsFieldsAndDateColumn() {
    let rendered = results(dateField: field("@timestamp"))
    let key = layoutKey(rendered, fields: [field("a")])

    XCTAssertNotEqual(key, layoutKey(results(dateField: field("@timestamp")), fields: [field("a")]))
    XCTAssertNotEqual(key, layoutKey(rendered, fields: [field("a"), field("b")]))
    XCTAssertNotEqual(key, layoutKey(rendered, fields: [field("a")], showDateHeader: false))
    XCTAssertNotEqual(key, layoutKey(rendered, fields: [field("a")], fieldsVersion: UUID()))

    var redated = rendered
    redated.dateField = field("event.created")
    XCTAssertNotEqual(key, layoutKey(redated, fields: [field("a")]))
  }

  func testLayoutCacheBuildsOnlyWhenKeyChanges() {
    let cache = macosTableLayoutCache()
    let rendered = results()
    var builds = 0
    func build() -> macosTableLayout {
      builds += 1
      return macosTableLayout(rows: [], autoWidths: [.field("a"): CGFloat(builds)], titleWidths: [:])
    }

    let first = cache.layout(for: layoutKey(rendered, fields: [field("a")]), build: build)
    let again = cache.layout(for: layoutKey(rendered, fields: [field("a")]), build: build)
    XCTAssertEqual(builds, 1)
    XCTAssertEqual(again.autoWidths, first.autoWidths)

    let changed = cache.layout(for: layoutKey(rendered, fields: [field("a"), field("b")]), build: build)
    XCTAssertEqual(builds, 2)
    XCTAssertEqual(changed.autoWidths[.field("a")], 2)
  }

  // MARK: - Width cache

  /// Counts what's measured, at three points per character
  final class CountingMeasure {
    var measured = [String]()
    func measure(_ text: String, _ bold: Bool) -> CGFloat {
      measured.append(text)
      return CGFloat(text.count * 3)
    }
  }

  func widthRows() -> [macosTableRow] {
    [
      row(["a": ["alpha"], "b": [String(repeating: "b", count: 40)], "c": ["c1"]], index: 0),
      row(["a": [String(repeating: "a", count: 30)], "b": ["bee"]], index: 1),
      row(["b": ["b2"], "c": [String(repeating: "c", count: 200)]], index: 2)
    ]
  }

  func testCachedWidthsMatchUncachedWidths() {
    let columns: [macosTableColumn] = [.field("a"), .field("b"), .field("c"), .document]
    let labels = ["b": "A label wider than the field path"]
    let counter = CountingMeasure()
    let cached = macosTableSearchView.columnWidths(columns: columns, rows: widthRows(), labels: labels,
                                                   cache: macosTableWidthCache(), measure: counter.measure)
    let uncached = macosTableSearchView.columnWidths(columns: columns, rows: widthRows(), labels: labels,
                                                     measure: counter.measure)
    XCTAssertEqual(cached, uncached)
    XCTAssertEqual(macosTableSearchView.titleWidths(columns: columns, labels: labels,
                                                    cache: macosTableWidthCache(), measure: counter.measure),
                   macosTableSearchView.titleWidths(columns: columns, labels: labels, measure: counter.measure))
  }

  func testWidthCacheMeasuresOnlyNewColumns() {
    let cache = macosTableWidthCache()
    cache.use(resultsID: UUID())
    let counter = CountingMeasure()
    _ = macosTableSearchView.columnWidths(columns: [.field("a")], rows: widthRows(),
                                          cache: cache, measure: counter.measure)
    counter.measured = []

    let widths = macosTableSearchView.columnWidths(columns: [.field("a"), .field("b")], rows: widthRows(),
                                                   cache: cache, measure: counter.measure)
    XCTAssertEqual(counter.measured.sorted(), ["b", "b2", "bee", String(repeating: "b", count: 40)].sorted(),
                   "Only the new column's header and cells should be measured")
    XCTAssertEqual(widths[.field("a")], 90 + macosTableSearchView.cellPadding)
    XCTAssertEqual(widths[.field("b")], 120 + macosTableSearchView.cellPadding)
  }

  func testWidthCacheFollowsTheRowsWithoutMeasuringAgain() {
    let cache = macosTableWidthCache()
    cache.use(resultsID: UUID())
    let counter = CountingMeasure()
    let all = widthRows()
    _ = macosTableSearchView.columnWidths(columns: [.field("a")], rows: all, cache: cache, measure: counter.measure)
    counter.measured = []

    // Without the row holding the long value, the column is sized to the shorter one
    let fewer = macosTableSearchView.columnWidths(columns: [.field("a")], rows: [all[0], all[2]],
                                                  cache: cache, measure: counter.measure)
    XCTAssertEqual(counter.measured, [])
    XCTAssertEqual(fewer[.field("a")], macosTableSearchView.minColumnWidth)
  }

  func testWidthCacheForgetsWidthsForNewResults() {
    let cache = macosTableWidthCache()
    cache.use(resultsID: UUID())
    let counter = CountingMeasure()
    _ = macosTableSearchView.columnWidths(columns: [.field("a")], rows: widthRows(), cache: cache, measure: counter.measure)
    cache.use(resultsID: UUID())
    counter.measured = []

    // Same row index, different document
    let widths = macosTableSearchView.columnWidths(columns: [.field("a")],
                                                   rows: [row(["a": [String(repeating: "z", count: 60)]], index: 1)],
                                                   cache: cache, measure: counter.measure)
    XCTAssertEqual(counter.measured.sorted(), ["a", String(repeating: "z", count: 60)].sorted())
    XCTAssertEqual(widths[.field("a")], 180 + macosTableSearchView.cellPadding)
  }

  func testWidthCacheMeasuresHeaderAgainWhenItsLabelChanges() {
    let cache = macosTableWidthCache()
    cache.use(resultsID: UUID())
    let counter = CountingMeasure()
    _ = macosTableSearchView.titleWidths(columns: [.field("a")], cache: cache, measure: counter.measure)
    _ = macosTableSearchView.titleWidths(columns: [.field("a")], cache: cache, measure: counter.measure)
    XCTAssertEqual(counter.measured, ["a"])

    let labelled = macosTableSearchView.titleWidths(columns: [.field("a")], labels: ["a": "Alpha"],
                                                    cache: cache, measure: counter.measure)
    XCTAssertEqual(labelled[.field("a")], 15)
  }

  func testLayoutCacheKeepsMeasuredWidthsForTheSameResults() {
    let cache = macosTableLayoutCache()
    let rendered = results()
    let counter = CountingMeasure()
    func build(_ fields: [String]) -> macosTableLayout {
      let columns = fields.map { macosTableColumn.field($0) }
      return macosTableLayout(rows: [],
                              autoWidths: macosTableSearchView.columnWidths(columns: columns, rows: widthRows(),
                                                                           cache: cache.widths,
                                                                           measure: counter.measure),
                              titleWidths: [:])
    }

    _ = cache.layout(for: layoutKey(rendered, fields: [field("a")])) { build(["a"]) }
    counter.measured = []
    _ = cache.layout(for: layoutKey(rendered, fields: [field("a")], fieldsVersion: UUID())) { build(["a"]) }
    XCTAssertEqual(counter.measured, [], "A new field selection with the same results reuses the widths")

    _ = cache.layout(for: layoutKey(results(), fields: [field("a")])) { build(["a"]) }
    XCTAssertFalse(counter.measured.isEmpty, "New results are measured again")
  }
}

#if os(macOS)
@MainActor
final class macosSearchHandoffTests: XCTestCase {

  func testASentSearchIsTakenOnce() {
    let handoff = macosSearchHandoff()
    XCTAssertNil(handoff.pendingId)
    XCTAssertNil(handoff.take())

    let request = SearchHandoffRequest(hostId: UUID(), index: "logs-*", dataView: nil, filterObject: FilterObject())
    handoff.send(request)
    let firstId = handoff.pendingId

    XCTAssertNotNil(firstId)
    XCTAssertEqual(handoff.take()?.index, "logs-*")
    XCTAssertNil(handoff.take())

    handoff.send(request)
    XCTAssertNotEqual(handoff.pendingId, firstId, "Each search sent is announced again")
  }
}
#endif
