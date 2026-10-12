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
  /// Set when the document wasn't in its saved index and was found by searching again
  public var move: SavedDocumentMove? = nil
}

/// A saved document found in another index than the one it was saved from, eg. after an ILM shrink or a searchable
/// snapshot mount
public struct SavedDocumentMove: Equatable {
  /// The index it was saved from
  public let from: String
  /// The new index is a renamed copy of the saved one, or the only one with the document, so it can be saved.
  /// Otherwise it's the newest of several documents with the same id: opened, but not saved.
  public let isCertain: Bool
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
  /// and keeps the id out of the URL. When it isn't there, eg. its index was shrunk or mounted from a snapshot under
  /// a new name, the pattern or data view it was found with is searched instead.
  /// `dataView` is the view looked up by the document's `dataViewId`, nil when it's been deleted.
  @MainActor
  public static func load(_ document: SavedDocument,
                          host: HostDetails,
                          dataView: DataView?) async -> SavedDocumentLoadResult {
    let response = await Search.searchIndex(serverDetails: host,
                                            index: document.docIndex,
                                            json: requestBody(docId: document.docId))
    let first = result(from: response, ref: document.ref)
    guard shouldSearchAgain(after: first),
          let index = fallbackIndex(for: document, dataView: dataView) else {
      return first
    }
    let fallback = fallbackResult(from: await Search.searchIndex(serverDetails: host,
                                                                 index: index,
                                                                 json: fallbackRequestBody(for: document)),
                                  document: document)
    // Not finding it again, or failing to search, says no more than the first answer did
    if case .found = fallback {
      return fallback
    }
    return first
  }

  public static func requestBody(docId: String) -> String {
    let body: [String: Any] = ["query": ["ids": ["values": [docId]]], "size": 1]
    guard let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]) else { return "" }
    return String(decoding: data, as: UTF8.self)
  }

  public static func result(from response: ServerResponse, ref: DocumentRef) -> SavedDocumentLoadResult {
    let parsed: SearchResult
    switch searchResult(from: response) {
    case .success(let result):
      parsed = result
    case .failure(let failure):
      return failure.result
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

  /// A failed search, as the load result it gives
  private struct LoadFailure: Error {
    let result: SavedDocumentLoadResult
  }

  private static func searchResult(from response: ServerResponse) -> Result<SearchResult, LoadFailure> {
    if let error = response.error {
      return .failure(LoadFailure(result: .failed(error)))
    }
    let parsed = Search.getObjects(input: response.parsed ?? "")
    if let error = parsed.error {
      // A deleted index answers with an error rather than no hits
      if parsed.errorTitle == "index_not_found_exception" {
        return .failure(LoadFailure(result: .notFound))
      }
      return .failure(LoadFailure(result: .failed(ResponseError(title: parsed.errorTitle ?? "Query Error",
                                                                message: error,
                                                                type: .critical))))
    }
    return .success(parsed)
  }

  // MARK: - Finding it in another index

  /// Prefixes added to an index's name when ILM shrinks it (`shrink-`) or a snapshot of it is mounted
  /// (`restored-` fully, `partial-` on the frozen tier)
  public static let copyPrefixes = ["shrink-", "restored-", "partial-"]

  /// How many documents with the same id the second search looks at
  public static let fallbackSize = 10

  /// The document wasn't in its index, or the index is closed, so it may have moved
  public static func shouldSearchAgain(after result: SavedDocumentLoadResult) -> Bool {
    switch result {
    case .notFound:
      return true
    case .failed(let error):
      return error.title == "index_closed_exception"
    case .found:
      return false
    }
  }

  /// What to search when the document isn't in its own index: the data view or pattern it was found with.
  /// nil when that's just its own index again.
  public static func fallbackIndex(for document: SavedDocument, dataView: DataView?) -> String? {
    let index = target(for: document, dataView: dataView).index
    return index == document.docIndex ? nil : index
  }

  /// Whether the second search can narrow and sort by the saved date field and time period
  public static func hasSavedPeriod(_ document: SavedDocument) -> Bool {
    guard let field = document.dateField?.field, !field.isEmpty else { return false }
    return document.timeRange != nil
  }

  /// Every document with the saved id, within the saved time period and newest first when there is one. The
  /// document was inside that period when it was saved, so it narrows out others with the same id without losing it.
  public static func fallbackRequestBody(for document: SavedDocument) -> String {
    var filters: [[String: Any]] = [["ids": ["values": [document.docId]]]]
    var body: [String: Any] = ["size": fallbackSize]
    if hasSavedPeriod(document), let field = document.dateField?.field, let range = document.timeRange {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      filters.append(["range": [field: ["gte": formatter.string(from: range.start),
                                        "lte": formatter.string(from: range.end),
                                        // Whatever format the field is mapped with, these dates are ISO 8601
                                        "format": "strict_date_optional_time"]]])
      // unmapped_type keeps indices without the field from failing the search
      body["sort"] = [[field: ["order": "desc", "unmapped_type": "date"]]]
    }
    body["query"] = ["bool": ["filter": filters]]
    guard let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]) else { return "" }
    return String(decoding: data, as: UTF8.self)
  }

  /// The document found by the second search, marked as moved when it's in another index
  public static func fallbackResult(from response: ServerResponse, document: SavedDocument) -> SavedDocumentLoadResult {
    let parsed: SearchResult
    switch searchResult(from: response) {
    case .success(let result):
      parsed = result
    case .failure(let failure):
      return failure.result
    }
    guard let match = bestMatch(refs: parsed.refs, original: document.ref, newestFirst: hasSavedPeriod(document)),
          match.position < parsed.rows.count,
          let ref = parsed.refs[match.position] else {
      return .notFound
    }
    let move = ref.index == document.docIndex ? nil : SavedDocumentMove(from: document.docIndex,
                                                                         isCertain: match.isCertain)
    return .found(SavedDocumentContent(ref: ref,
                                       row: parsed.rows[match.position],
                                       fields: parsed.fields,
                                       move: move))
  }

  /// Which hit is the saved document, by position, and whether that's certain enough to save its new index.
  /// Only hits with the same id count. Certain: its own index, a renamed copy of it, or the only hit.
  /// Otherwise the newest: the first hit when they're sorted newest first, else the index whose name sorts last,
  /// which is the newest for rollover (`-000002`) and dated (`logs-2026.10.10`) names.
  public static func bestMatch(refs: [DocumentRef?],
                               original: DocumentRef,
                               newestFirst: Bool) -> (position: Int, isCertain: Bool)? {
    let candidates: [(position: Int, index: String)] = refs.enumerated().compactMap { position, ref in
      guard let ref = ref, ref.id == original.id else { return nil }
      return (position, ref.index)
    }
    guard let first = candidates.first else { return nil }
    if let same = candidates.first(where: { $0.index == original.index }) {
      return (same.position, true)
    }
    if let copy = candidates.first(where: { isRenamedCopy($0.index, of: original.index) }) {
      return (copy.position, true)
    }
    if candidates.count == 1 {
      return (first.position, true)
    }
    if newestFirst {
      return (first.position, false)
    }
    let newest = candidates.max { $0.index.compare($1.index, options: .numeric) == .orderedAscending } ?? first
    return (newest.position, false)
  }

  /// Whether two different indices are copies of each other, eg. `logs-1` and `shrink-ab1c-logs-1`,
  /// `restored-logs-1` or `partial-shrink-ab1c-logs-1`
  public static func isRenamedCopy(_ index: String, of original: String) -> Bool {
    guard index != original else { return false }
    return !originalNames(of: index).isDisjoint(with: originalNames(of: original))
  }

  /// The index and every name it could have been copied from, taking off the copy prefixes one at a time.
  /// ILM's shrink can add four random characters as well, eg. `shrink-ab1c-logs-1`.
  static func originalNames(of index: String) -> Set<String> {
    var names: Set<String> = [index]
    var pending = [index]
    while let name = pending.popLast() {
      for prefix in copyPrefixes where name.hasPrefix(prefix) {
        let rest = String(name.dropFirst(prefix.count))
        var next = [rest]
        if prefix == "shrink-", let dash = rest.firstIndex(of: "-"),
           rest.distance(from: rest.startIndex, to: dash) == 4 {
          next.append(String(rest[rest.index(after: dash)...]))
        }
        for candidate in next where !candidate.isEmpty && names.insert(candidate).inserted {
          pending.append(candidate)
        }
      }
    }
    return names
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
