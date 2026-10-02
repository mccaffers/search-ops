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

  // MARK: - Rows

  func testVisibleRowsMatchDocumentLayout() {
    let dateField = field("@timestamp")
    let flat: [OrderedDictionary<String, Any>] = [
      ["@timestamp": ["2026-09-20T12:00:00"], "message": ["hello"]],
      ["@timestamp": ["2026-09-20T12:01:00"], "status": ["200"]],
      ["@timestamp": ["2026-09-20T12:02:00"], "message": [""]],
      ["message": ["   "]],
      ["@timestamp": ["2026-09-20T12:03:00"], "message": ["bye"], "status": ["500"]]
    ]

    for filteredFields in [[], [field("message")], [field("message"), field("status")]] {
      for showDateHeader in [true, false] {
        let expected = flat.indices.filter {
          macOSDocumentSearchView.processRow(item: flat[$0],
                                             dateField: dateField,
                                             filteredFields: filteredFields,
                                             showDateHeader: showDateHeader).shouldShowRow
        }
        let rows = macosTableSearchView.visibleRows(flatArray: flat,
                                                    dateField: dateField,
                                                    filteredFields: filteredFields,
                                                    showDateHeader: showDateHeader)
        XCTAssertEqual(rows.map(\.index), expected,
                       "fields: \(filteredFields.map(\.squashedString)), date header: \(showDateHeader)")
      }
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
}
