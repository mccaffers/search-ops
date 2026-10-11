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
