// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing

@testable import Search_Ops

struct SavedDocumentSearchTests {

  let hostId = UUID()

  private func response(_ body: String, error: ResponseError? = nil) -> ServerResponse {
    let response = ServerResponse(error: error)
    response.parsed = body
    return response
  }

  private func savedDocument(searchIndex: String = "logs-*",
                             dataViewId: UUID? = nil,
                             dateField: SavedDateField? = nil,
                             timeRange: DateInterval? = nil) -> SavedDocument {
    SavedDocument(hostId: hostId,
                  docIndex: "logs-2026.10.10",
                  docId: "abc",
                  searchIndex: searchIndex,
                  dataViewId: dataViewId,
                  dateField: dateField,
                  timeRange: timeRange)
  }

  // MARK: - Document references in search results

  @Test func searchResultsKeepEachHitsIndexAndId() {
    let body = """
    {"hits": {"total": {"value": 3}, "hits": [
      {"_index": "logs-2026.10.10", "_id": "a", "_source": {"message": "one"}},
      {"_index": "logs-2026.10.11", "_id": "b", "_source": {"message": "two"}},
      {"_index": "logs-2026.10.11", "_source": {"message": "three"}}
    ]}}
    """
    let result = Search.getObjects(input: body)

    #expect(result.rows.count == 3)
    #expect(result.refs == [DocumentRef(index: "logs-2026.10.10", id: "a"),
                            DocumentRef(index: "logs-2026.10.11", id: "b"),
                            nil])
    // The id isn't shown as one of the document's fields
    #expect(!result.fields.contains { $0.squashedString == "_id" })
  }

  @Test func refsStayInLineWithRowsWhenAHitHasNoSource() {
    let body = """
    {"hits": {"hits": [
      {"_index": "logs", "_id": "a"},
      {"_index": "logs", "_id": "b", "_source": {"message": "two"}}
    ]}}
    """
    let result = Search.getObjects(input: body)

    #expect(result.rows.count == 1)
    #expect(result.refs == [DocumentRef(index: "logs", id: "b")])
    #expect((result.rows.first?["message"] as? [String]) == ["two"])
  }

  // MARK: - Loading a saved document

  @Test func requestBodyAsksForTheIdOnly() throws {
    let body = SavedDocumentSearch.requestBody(docId: "a\"b")
    let json = try #require(JsonTools.serialiseJson(body))
    let query = try #require(json["query"] as? [String: Any])
    let ids = try #require(query["ids"] as? [String: Any])
    #expect(ids["values"] as? [String] == ["a\"b"])
    #expect(json["size"] as? Int == 1)
  }

  @Test func loadFindsTheDocument() throws {
    let body = """
    {"hits": {"hits": [{"_index": "logs-2026.10.10", "_id": "abc", "_source": {"user": {"name": "ana"}}}]}}
    """
    let result = SavedDocumentSearch.result(from: response(body), ref: DocumentRef(index: "logs-2026.10.10", id: "abc"))

    guard case .found(let content) = result else {
      Issue.record("Expected the document, got \(result)")
      return
    }
    #expect(content.ref == DocumentRef(index: "logs-2026.10.10", id: "abc"))
    #expect((content.row["user.name"] as? [String]) == ["ana"])
    #expect(content.fields.map(\.squashedString) == ["user.name"])
  }

  @Test func loadIgnoresHitsWithAnotherId() {
    let body = """
    {"hits": {"hits": [{"_index": "logs", "_id": "other", "_source": {"message": "x"}}]}}
    """
    let result = SavedDocumentSearch.result(from: response(body), ref: DocumentRef(index: "logs", id: "abc"))
    guard case .notFound = result else {
      Issue.record("Expected not found, got \(result)")
      return
    }
  }

  @Test func loadWithNoHitsIsNotFound() {
    let result = SavedDocumentSearch.result(from: response(#"{"hits": {"total": {"value": 0}, "hits": []}}"#),
                                            ref: DocumentRef(index: "logs", id: "abc"))
    guard case .notFound = result else {
      Issue.record("Expected not found, got \(result)")
      return
    }
  }

  @Test func loadFromADeletedIndexIsNotFound() {
    let body = """
    {"error": {"root_cause": [{"type": "index_not_found_exception", "reason": "no such index [logs]"}],
               "type": "index_not_found_exception", "reason": "no such index [logs]"}, "status": 404}
    """
    let result = SavedDocumentSearch.result(from: response(body), ref: DocumentRef(index: "logs", id: "abc"))
    guard case .notFound = result else {
      Issue.record("Expected not found, got \(result)")
      return
    }
  }

  @Test func loadReportsOtherErrors() {
    let body = """
    {"error": {"root_cause": [{"type": "security_exception", "reason": "action is unauthorized"}]}, "status": 403}
    """
    let result = SavedDocumentSearch.result(from: response(body), ref: DocumentRef(index: "logs", id: "abc"))
    guard case .failed(let error) = result else {
      Issue.record("Expected an error, got \(result)")
      return
    }
    #expect(error.title == "security_exception")
    #expect(error.message == "action is unauthorized")
  }

  @Test func loadReportsRequestErrors() {
    let requestError = ResponseError(title: "Request Error", message: "Request timed out", type: .critical)
    let result = SavedDocumentSearch.result(from: response("", error: requestError),
                                            ref: DocumentRef(index: "logs", id: "abc"))
    guard case .failed(let error) = result else {
      Issue.record("Expected an error, got \(result)")
      return
    }
    #expect(error.message == "Request timed out")
  }

  // MARK: - Finding a moved document

  private func hits(_ pairs: [(index: String, id: String)]) -> ServerResponse {
    let hits = pairs.map { #"{"_index": "\#($0.index)", "_id": "\#($0.id)", "_source": {"message": "\#($0.index)"}}"# }
    return response(#"{"hits": {"hits": [\#(hits.joined(separator: ","))]}}"#)
  }

  private func refs(_ indices: [String], id: String = "abc") -> [DocumentRef?] {
    indices.map { DocumentRef(index: $0, id: id) }
  }

  @Test func renamedCopiesAreRecognised() {
    let copy = SavedDocumentSearch.isRenamedCopy
    #expect(copy("shrink-logs-1", "logs-1"))
    #expect(copy("shrink-ab1c-logs-1", "logs-1"))
    #expect(copy("restored-logs-1", "logs-1"))
    #expect(copy("partial-logs-1", "logs-1"))
    #expect(copy("partial-shrink-ab1c-logs-1", "logs-1"))
    #expect(copy("shrink-ab1c-.ds-logs-app-2026.10.01-000001", ".ds-logs-app-2026.10.01-000001"))
    // Either way round, and two copies of the same index
    #expect(copy("logs-1", "restored-logs-1"))
    #expect(copy("restored-logs-1", "partial-logs-1"))
  }

  @Test func otherIndicesAreNotRenamedCopies() {
    let copy = SavedDocumentSearch.isRenamedCopy
    #expect(!copy("logs-1", "logs-1"))
    #expect(!copy("logs-2", "logs-1"))
    #expect(!copy("shrink-logs-2", "logs-1"))
    #expect(!copy("snapshot-logs-1", "logs-1"))
    #expect(!copy("shrink-abcde-logs-1", "logs-1"))
  }

  @Test func bestMatchPrefersTheSavedIndexThenARenamedCopy() throws {
    let original = DocumentRef(index: "logs-1", id: "abc")

    let same = try #require(SavedDocumentSearch.bestMatch(refs: refs(["logs-2", "logs-1"]), original: original,
                                                          newestFirst: true))
    #expect(same.position == 1)
    #expect(same.isCertain)

    // A copy wins over a newer, unrelated index
    let copy = try #require(SavedDocumentSearch.bestMatch(refs: refs(["logs-9", "shrink-ab1c-logs-1"]),
                                                          original: original, newestFirst: true))
    #expect(copy.position == 1)
    #expect(copy.isCertain)
  }

  @Test func bestMatchTakesTheOnlyHitAsCertain() throws {
    let match = try #require(SavedDocumentSearch.bestMatch(refs: refs(["archive-2026"]),
                                                           original: DocumentRef(index: "logs-1", id: "abc"),
                                                           newestFirst: false))
    #expect(match.position == 0)
    #expect(match.isCertain)
  }

  @Test func bestMatchTakesTheNewestOfSeveralButIsntCertain() throws {
    let original = DocumentRef(index: "logs-1", id: "abc")

    // Sorted by the date field, newest first
    let sorted = try #require(SavedDocumentSearch.bestMatch(refs: refs(["archive-b", "archive-a"]), original: original,
                                                            newestFirst: true))
    #expect(sorted.position == 0)
    #expect(!sorted.isCertain)

    // Otherwise the index name that sorts last, numbers compared as numbers
    let dated = refs(["app-2026.10.10", "app-2026.10.9", "app-2026.9.30"])
    let byName = try #require(SavedDocumentSearch.bestMatch(refs: dated, original: original, newestFirst: false))
    #expect(byName.position == 0)
    #expect(!byName.isCertain)
  }

  @Test func bestMatchIgnoresOtherIds() {
    let original = DocumentRef(index: "logs-1", id: "abc")
    let others: [DocumentRef?] = [DocumentRef(index: "shrink-logs-1", id: "other"), nil]
    #expect(SavedDocumentSearch.bestMatch(refs: others, original: original, newestFirst: false) == nil)

    let mixed: [DocumentRef?] = [DocumentRef(index: "logs-9", id: "other"), DocumentRef(index: "logs-2", id: "abc")]
    let match = SavedDocumentSearch.bestMatch(refs: mixed, original: original, newestFirst: false)
    #expect(match?.position == 1)
    #expect(match?.isCertain == true)
  }

  @Test func fallbackSearchesThePatternOrDataView() {
    let view = DataView(hostId: hostId, name: "Logs", pattern: "logs-*,metrics-*")
    #expect(SavedDocumentSearch.fallbackIndex(for: savedDocument(dataViewId: view.id), dataView: view)
            == "logs-*,metrics-*")
    #expect(SavedDocumentSearch.fallbackIndex(for: savedDocument(searchIndex: "logs-*"), dataView: nil) == "logs-*")
  }

  @Test func noFallbackWhenOnlyItsOwnIndexWasSearched() {
    #expect(SavedDocumentSearch.fallbackIndex(for: savedDocument(searchIndex: ""), dataView: nil) == nil)
    #expect(SavedDocumentSearch.fallbackIndex(for: savedDocument(searchIndex: "logs-2026.10.10"), dataView: nil) == nil)
  }

  @Test func searchesAgainOnlyWhenNotFoundOrClosed() {
    #expect(SavedDocumentSearch.shouldSearchAgain(after: .notFound))
    let closed = ResponseError(title: "index_closed_exception", message: "closed", type: .critical)
    #expect(SavedDocumentSearch.shouldSearchAgain(after: .failed(closed)))
    let other = ResponseError(title: "security_exception", message: "denied", type: .critical)
    #expect(!SavedDocumentSearch.shouldSearchAgain(after: .failed(other)))
    let found = SavedDocumentContent(ref: DocumentRef(index: "logs", id: "abc"), row: [:], fields: [])
    #expect(!SavedDocumentSearch.shouldSearchAgain(after: .found(found)))
  }

  @Test func fallbackRequestNarrowsToTheSavedPeriodNewestFirst() throws {
    let range = DateInterval(start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 5_000.5))
    let document = savedDocument(dateField: SavedDateField(field: "@timestamp", type: "date"), timeRange: range)

    let body = SavedDocumentSearch.fallbackRequestBody(for: document)

    let json = try #require(JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
    #expect(json["size"] as? Int == SavedDocumentSearch.fallbackSize)
    let query = try #require(json["query"] as? [String: Any])
    let filters = try #require((query["bool"] as? [String: Any])?["filter"] as? [[String: Any]])
    #expect(((filters.first?["ids"] as? [String: Any])?["values"] as? [String]) == ["abc"])
    let range0 = try #require((filters.last?["range"] as? [String: Any])?["@timestamp"] as? [String: String])
    #expect(range0["gte"] == "1970-01-01T00:16:40.000Z")
    #expect(range0["lte"] == "1970-01-01T01:23:20.500Z")
    #expect(range0["format"] == "strict_date_optional_time")
    let sort = try #require(json["sort"] as? [[String: [String: String]]])
    #expect(sort == [["@timestamp": ["order": "desc", "unmapped_type": "date"]]])
  }

  @Test func fallbackRequestWithoutAPeriodIsJustTheId() throws {
    // A field without a period, or a period without a field, can't narrow anything
    for document in [savedDocument(dateField: SavedDateField(field: "@timestamp")),
                     savedDocument(timeRange: DateInterval(start: .distantPast, end: .now))] {
      let body = SavedDocumentSearch.fallbackRequestBody(for: document)
      let json = try #require(JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
      let query = try #require(json["query"] as? [String: Any])
      let filters = try #require((query["bool"] as? [String: Any])?["filter"] as? [[String: Any]])
      #expect(filters.count == 1)
      #expect(json["sort"] == nil)
    }
  }

  @Test func fallbackFindsARenamedCopyAndCanSaveIt() throws {
    let response = hits([("logs-9", "abc"), ("shrink-ab1c-logs-2026.10.10", "abc")])
    let result = SavedDocumentSearch.fallbackResult(from: response, document: savedDocument())
    guard case .found(let content) = result else {
      Issue.record("Expected the document, got \(result)")
      return
    }
    #expect(content.ref == DocumentRef(index: "shrink-ab1c-logs-2026.10.10", id: "abc"))
    #expect((content.row["message"] as? [String]) == ["shrink-ab1c-logs-2026.10.10"])
    #expect(content.move == SavedDocumentMove(from: "logs-2026.10.10", isCertain: true))
  }

  @Test func fallbackOpensTheNewestOfSeveralWithoutSavingIt() throws {
    let range = DateInterval(start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 5_000))
    let document = savedDocument(dateField: SavedDateField(field: "@timestamp"), timeRange: range)
    let result = SavedDocumentSearch.fallbackResult(from: hits([("archive-b", "abc"), ("archive-a", "abc")]),
                                                    document: document)
    guard case .found(let content) = result else {
      Issue.record("Expected the document, got \(result)")
      return
    }
    #expect(content.ref.index == "archive-b")
    #expect(content.move == SavedDocumentMove(from: "logs-2026.10.10", isCertain: false))
  }

  @Test func fallbackInTheSavedIndexIsNotAMove() {
    let result = SavedDocumentSearch.fallbackResult(from: hits([("logs-2026.10.10", "abc")]), document: savedDocument())
    guard case .found(let content) = result else {
      Issue.record("Expected the document, got \(result)")
      return
    }
    #expect(content.move == nil)
  }

  @Test func fallbackWithoutTheIdIsNotFound() {
    let result = SavedDocumentSearch.fallbackResult(from: hits([("shrink-logs-2026.10.10", "other")]),
                                                    document: savedDocument())
    guard case .notFound = result else {
      Issue.record("Expected not found, got \(result)")
      return
    }
  }

  // MARK: - Where a search from a saved document runs

  @Test func searchUsesTheDataViewWhileItExists() {
    let view = DataView(hostId: hostId, name: "Logs", pattern: " logs-*,metrics-* ")
    let document = savedDocument(searchIndex: "logs-*", dataViewId: view.id)

    let target = SavedDocumentSearch.target(for: document, dataView: view)

    #expect(target.index == "logs-*,metrics-*")
    #expect(target.dataView == view)
  }

  @Test func searchFallsBackToTheSavedPatternWhenTheDataViewIsGone() {
    let document = savedDocument(searchIndex: "logs-*", dataViewId: UUID())
    let target = SavedDocumentSearch.target(for: document, dataView: nil)
    #expect(target.index == "logs-*")
    #expect(target.dataView == nil)
  }

  @Test func searchIgnoresADataViewThatIsntTheSavedOne() {
    let otherView = DataView(hostId: hostId, name: "Other", pattern: "other-*")
    let document = savedDocument(searchIndex: "logs-*", dataViewId: UUID())
    #expect(SavedDocumentSearch.target(for: document, dataView: otherView).index == "logs-*")

    let viewOnAnotherHost = DataView(hostId: UUID(), name: "Logs", pattern: "elsewhere-*")
    let sameIdDocument = savedDocument(searchIndex: "logs-*", dataViewId: viewOnAnotherHost.id)
    #expect(SavedDocumentSearch.target(for: sameIdDocument, dataView: viewOnAnotherHost).index == "logs-*")
  }

  @Test func searchUsesTheSingleIndexThatWasSearched() {
    let document = savedDocument(searchIndex: "orders")
    #expect(SavedDocumentSearch.target(for: document, dataView: nil).index == "orders")
  }

  @Test func searchFallsBackToTheDocumentsOwnIndex() {
    let document = savedDocument(searchIndex: "  ")
    #expect(SavedDocumentSearch.target(for: document, dataView: nil).index == "logs-2026.10.10")
  }

  // MARK: - Searching for a value

  @Test func termSearchUsesTheSavedDateFieldAndFixedPeriod() throws {
    let range = DateInterval(start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 5_000))
    let document = savedDocument(dateField: SavedDateField(field: "event.created", type: "date"), timeRange: range)

    let request = SavedDocumentSearch.termSearch(for: document, field: "user.name", value: "ana",
                                                 negated: true, dataView: nil)

    #expect(request.hostId == hostId)
    #expect(request.index == "logs-*")
    #expect(request.dataView == nil)
    let filter = request.filterObject
    #expect(filter.dateField?.squashedString == "event.created")
    #expect(filter.dateField?.fieldParts == ["event", "created"])
    #expect(filter.relativeRange == nil)
    let absolute = try #require(filter.absoluteRange)
    #expect(absolute.from == range.start)
    #expect(absolute.to == range.end)
    #expect(!absolute.fromNow && !absolute.toNow)
    #expect(filter.fieldFilters.count == 1)
    #expect(filter.fieldFilters.first?.field == "user.name")
    #expect(filter.fieldFilters.first?.value == "ana")
    #expect(filter.fieldFilters.first?.negated == true)
  }

  @Test func termSearchWithoutADateFieldHasNoPeriod() {
    let range = DateInterval(start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 5_000))
    let document = savedDocument(timeRange: range)

    let request = SavedDocumentSearch.termSearch(for: document, field: "user.name", value: "ana",
                                                 negated: false, dataView: nil)

    #expect(request.filterObject.dateField == nil)
    #expect(request.filterObject.absoluteRange == nil)
    #expect(request.filterObject.fieldFilters.first?.negated == false)
  }
}
