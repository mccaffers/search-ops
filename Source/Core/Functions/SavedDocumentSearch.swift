// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import OrderedCollections

/// A saved document fetched again: its fields flattened as the Document panel shows them, and its fields list.
public struct SavedDocumentContent {
  public let ref: DocumentRef
  public let row: OrderedDictionary<String, Any>
  public let fields: [SquashedFieldsArray]
}

public enum SavedDocumentLoadResult {
  case found(SavedDocumentContent)
  /// The document, or its whole index, has been deleted
  case notFound
  case failed(ResponseError)
}

/// A search to run in the Search tab, sent from the Saved tab
public struct SearchHandoffRequest {
  public let hostId: UUID
  public let index: String
  public let dataView: DataView?
  public let filterObject: FilterObject
  /// The fields to show as columns, in order. nil leaves the Search tab to pick, as for any new search.
  public var selectedFields: [String]? = nil
  /// Column widths to restore, keyed as `SavedSearch.columnWidths`. nil leaves the columns to size themselves.
  public var columnWidths: [String: Double]? = nil
  /// The saved search being opened, so saving again can update it
  public var savedSearch: SavedSearch? = nil
}

@available(macOS 13.0, *)
@available(iOS 16.0, *)
public enum SavedDocumentSearch {

  // MARK: - Loading the document

  /// Fetches a saved document from its own index. An `ids` search finds it without knowing its routing,
  /// and keeps the id out of the URL.
  @MainActor
  public static func load(_ document: SavedDocument, host: HostDetails) async -> SavedDocumentLoadResult {
    let response = await Search.searchIndex(serverDetails: host,
                                            index: document.docIndex,
                                            json: requestBody(docId: document.docId))
    return result(from: response, ref: document.ref)
  }

  public static func requestBody(docId: String) -> String {
    let body: [String: Any] = ["query": ["ids": ["values": [docId]]], "size": 1]
    guard let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]) else { return "" }
    return String(decoding: data, as: UTF8.self)
  }

  public static func result(from response: ServerResponse, ref: DocumentRef) -> SavedDocumentLoadResult {
    if let error = response.error {
      return .failed(error)
    }
    let parsed = Search.getObjects(input: response.parsed ?? "")
    if let error = parsed.error {
      // A deleted index answers with an error rather than no hits
      if parsed.errorTitle == "index_not_found_exception" {
        return .notFound
      }
      return .failed(ResponseError(title: parsed.errorTitle ?? "Query Error", message: error, type: .critical))
    }
    // Only take the hit that's really this document, in case an index alias spans several indices
    guard let position = parsed.refs.firstIndex(where: { $0?.id == ref.id }),
          position < parsed.rows.count else {
      return .notFound
    }
    return .found(SavedDocumentContent(ref: parsed.refs[position] ?? ref,
                                       row: parsed.rows[position],
                                       fields: parsed.fields))
  }

  // MARK: - Searching for its values

  /// Where a search from a saved document runs: the data view it was saved from while that still exists,
  /// otherwise the pattern or index that was searched, and the document's own index as a last resort.
  /// `dataView` is the view looked up by the document's `dataViewId`, nil when it's been deleted.
  public static func target(for document: SavedDocument, dataView: DataView?) -> (index: String, dataView: DataView?) {
    target(hostId: document.hostId,
           dataViewId: document.dataViewId,
           searchIndex: document.searchIndex,
           fallback: document.docIndex,
           dataView: dataView)
  }

  /// The data view while it's still the saved one on the same host, otherwise `searchIndex`, otherwise `fallback`
  public static func target(hostId: UUID,
                            dataViewId: UUID?,
                            searchIndex: String,
                            fallback: String,
                            dataView: DataView?) -> (index: String, dataView: DataView?) {
    if let view = dataView,
       view.id == dataViewId,
       view.hostId == hostId {
      let pattern = view.normalized().pattern
      if !pattern.isEmpty {
        return (pattern, view)
      }
    }
    let searched = searchIndex.trimmingCharacters(in: .whitespacesAndNewlines)
    if !searched.isEmpty {
      return (searched, nil)
    }
    return (fallback, nil)
  }

  /// A search for documents with (or, when negated, without) a field's value, over the saved date field and
  /// fixed time period
  public static func termSearch(for document: SavedDocument,
                                field: String,
                                value: String,
                                negated: Bool,
                                dataView: DataView?) -> SearchHandoffRequest {
    let target = target(for: document, dataView: dataView)
    let filterObject = FilterObject()
    if let dateField = document.dateField {
      filterObject.dateField = dateField.squashedField()
      if let range = document.timeRange {
        filterObject.absoluteRange = AbsoluteDateRangeObject(from: range.start, to: range.end)
      }
    }
    filterObject.addFieldFilter(field: field, value: value, negated: negated)
    return SearchHandoffRequest(hostId: document.hostId,
                                      index: target.index,
                                      dataView: target.dataView,
                                      filterObject: filterObject)
  }
}
