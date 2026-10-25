// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import OrderedCollections

/// A column of a dashboard panel's table
public enum DashboardColumn: Hashable {
  case date(String)
  case field(String)
  /// Every field of the document in one line, when the search was saved without columns
  case document

  public var title: String {
    switch self {
    case .date(let key), .field(let key):
      return key
    case .document:
      return "Document"
    }
  }
}

/// A document in a panel's table, as the text of each of its cells. nil is a field the document doesn't have.
public struct DashboardRow: Identifiable, Equatable {
  public let id: Int
  public let cells: [String?]
}

/// What a panel's search found, ready to show
public struct DashboardPanelResult {
  public var columns: [DashboardColumn] = []
  public var rows: [DashboardRow] = []
  public var hits: Int = 0
  /// The server stopped counting at `hits`, so there are at least that many
  public var hitsIsLowerBound: Bool = false
  public var duration: Duration? = nil
  public var error: ResponseError? = nil

  public init(columns: [DashboardColumn] = [],
              rows: [DashboardRow] = [],
              hits: Int = 0,
              hitsIsLowerBound: Bool = false,
              duration: Duration? = nil,
              error: ResponseError? = nil) {
    self.columns = columns
    self.rows = rows
    self.hits = hits
    self.hitsIsLowerBound = hitsIsLowerBound
    self.duration = duration
    self.error = error
  }
}

/// Runs a saved search for a dashboard panel: its first few documents, with the columns it was saved with
@available(macOS 13.0, *)
@available(iOS 16.0, *)
public enum DashboardPanelSearch {

  /// The longest a document summary cell gets, in characters
  static let summaryLength = 300

  /// Searches `host` for the first `rowLimit` documents of `search`. `dataView` is the view looked up by the
  /// search's `dataViewId`, nil once it's deleted. Pass a copy of the host, the search outlives the call.
  /// Nothing is added to Recent Searches: a panel refreshing isn't someone searching.
  @MainActor
  public static func run(_ search: SavedSearch,
                         host: HostDetails,
                         dataView: DataView?,
                         rowLimit: Int) async -> DashboardPanelResult {
    let request = search.request(dataView: dataView)
    let response = await SearchRender.call(pageInput: 1,
                                           filterObject: request.filterObject,
                                           host: host,
                                           index: request.index,
                                           limitObj: LimitObj(size: rowLimit),
                                           size: rowLimit)
    if let error = response.error {
      return DashboardPanelResult(duration: response.duration, error: error)
    }
    let columns = columns(dateField: search.dateField?.field, selectedFields: search.selectedFields)
    return DashboardPanelResult(columns: columns,
                                rows: rows(response.rows, columns: columns, dateField: search.dateField?.field),
                                hits: response.hits,
                                hitsIsLowerBound: response.hitsIsLowerBound,
                                duration: response.duration)
  }

  /// The date column first when there's a date field, then the saved columns in order, or one document column
  /// when none were saved. As the Search tab shows the search.
  public static func columns(dateField: String?, selectedFields: [String]) -> [DashboardColumn] {
    var columns = [DashboardColumn]()
    if let dateField = dateField, !dateField.isEmpty {
      columns.append(.date(dateField))
    }
    let fields = selectedFields.filter { $0 != dateField }
    if fields.isEmpty {
      columns.append(.document)
    } else {
      columns.append(contentsOf: fields.map { .field($0) })
    }
    return columns
  }

  /// Each flattened document as the text of its cells
  public static func rows(_ documents: [OrderedDictionary<String, Any>],
                          columns: [DashboardColumn],
                          dateField: String?) -> [DashboardRow] {
    documents.enumerated().map { index, document in
      DashboardRow(id: index, cells: columns.map { text(for: $0, in: document, dateField: dateField) })
    }
  }

  /// A cell's text: the date formatted, a field's values joined into one line, or every field but the date
  /// as "field: value" pairs. nil when there's nothing to show.
  public static func text(for column: DashboardColumn,
                          in document: OrderedDictionary<String, Any>,
                          dateField: String?) -> String? {
    switch column {
    case .date(let key):
      guard let raw = values(for: key, in: document).first else { return nil }
      let formatted = DateTools.buildDateLarge(input: raw)
      return formatted.isEmpty ? raw : formatted
    case .field(let key):
      let found = values(for: key, in: document)
      return found.isEmpty ? nil : found.joined(separator: ", ")
    case .document:
      return summary(of: document, leavingOut: dateField)
    }
  }

  /// "field: value  field: value", cut off at `summaryLength`
  static func summary(of document: OrderedDictionary<String, Any>, leavingOut dateField: String?) -> String? {
    var parts = [String]()
    var length = 0
    for key in document.keys where key != dateField {
      let found = values(for: key, in: document)
      guard !found.isEmpty else { continue }
      let part = "\(key): \(found.joined(separator: ", "))"
      // The length once joined, counting the gap before each part but the first
      length += part.count + (parts.isEmpty ? 0 : 2)
      parts.append(part)
      if length > summaryLength { break }
    }
    guard !parts.isEmpty else { return nil }
    let joined = parts.joined(separator: "  ")
    return joined.count > summaryLength ? String(joined.prefix(summaryLength)) + "…" : joined
  }

  /// The non-blank values of a field, as the Search table counts them
  static func values(for key: String, in document: OrderedDictionary<String, Any>) -> [String] {
    guard let values = document[key] as? [String] else { return [] }
    return values.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
  }
}
