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

struct SavedDocumentTests {

  let hostId = UUID()
  let ref = DocumentRef(index: "logs-2026.10.10", id: "abc")
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  private func dateField(_ name: String = "@timestamp") -> SquashedFieldsArray {
    let field = SquashedFieldsArray(squashedString: name, fieldParts: name.components(separatedBy: "."))
    field.type = "date"
    return field
  }

  // MARK: - Fixed time periods

  @Test func relativePeriodIsPinnedToWhenItWasSaved() {
    let range = SavedDocument.fixedRange(.relative(value: 24, period: .Hours), now: now)
    #expect(range == DateInterval(start: now - 24 * 3600, end: now))
  }

  @Test func absolutePeriodIsKept() {
    let from = now - 600
    let to = now - 60
    let range = SavedDocument.fixedRange(.absolute(from: from, to: to, fromNow: false, toNow: false), now: now)
    #expect(range == DateInterval(start: from, end: to))
  }

  @Test func absolutePeriodEndingNowEndsWhenItWasSaved() {
    let from = now - 600
    let range = SavedDocument.fixedRange(.absolute(from: from, to: Date.distantPast, fromNow: false, toNow: true),
                                         now: now)
    #expect(range == DateInterval(start: from, end: now))
  }

  @Test func reversedPeriodIsPutInOrder() {
    let range = SavedDocument.fixedRange(.absolute(from: now, to: now - 60, fromNow: false, toNow: false), now: now)
    #expect(range == DateInterval(start: now - 60, end: now))
  }

  @Test func noPeriodIsNil() {
    #expect(SavedDocument.fixedRange(nil, now: now) == nil)
  }

  // MARK: - Making a saved document

  @Test func makeKeepsTheSearchItCameFrom() {
    let view = DataView(hostId: hostId, name: "Logs", pattern: "logs-*")

    let document = SavedDocument.make(hostId: hostId,
                                      ref: ref,
                                      searchIndex: "logs-*",
                                      dataView: view,
                                      dateField: dateField("event.created"),
                                      dateRange: .relative(value: 15, period: .Minutes),
                                      now: now)

    #expect(document.hostId == hostId)
    #expect(document.docIndex == "logs-2026.10.10")
    #expect(document.docId == "abc")
    #expect(document.searchIndex == "logs-*")
    #expect(document.dataViewId == view.id)
    #expect(document.dateField == SavedDateField(field: "event.created", parts: ["event", "created"], type: "date"))
    #expect(document.timeRange == DateInterval(start: now - 900, end: now))
    #expect(document.savedDate == now)
    #expect(document.title == "")
    #expect(document.displayTitle == "logs-2026.10.10 / abc")
  }

  @Test func makeWithoutADateFieldSavesNoPeriod() {
    let document = SavedDocument.make(hostId: hostId,
                                      ref: ref,
                                      searchIndex: "logs-2026.10.10",
                                      dataView: nil,
                                      dateField: nil,
                                      dateRange: .relative(value: 15, period: .Minutes),
                                      now: now)
    #expect(document.dateField == nil)
    #expect(document.timeRange == nil)
    #expect(document.dataViewId == nil)
  }

  // MARK: - Showing saved documents

  @Test func groupsFollowTheHostOrderAndAreNewestFirst() {
    let firstHost = UUID()
    let secondHost = UUID()
    let goneHost = UUID()
    let old = SavedDocument(hostId: secondHost, docIndex: "logs", docId: "old", savedDate: now - 100)
    let new = SavedDocument(hostId: secondHost, docIndex: "logs", docId: "new", savedDate: now)
    let other = SavedDocument(hostId: firstHost, docIndex: "logs", docId: "other", savedDate: now - 50)
    let orphan = SavedDocument(hostId: goneHost, docIndex: "logs", docId: "orphan", savedDate: now)

    let groups = SavedDocument.grouped([old, other, orphan, new],
                                       hosts: [(firstHost, "Production"), (UUID(), "Empty"), (secondHost, "Staging")])

    #expect(groups.map(\.hostName) == ["Production", "Staging"])
    #expect(groups.map(\.id) == [firstHost, secondHost])
    #expect(groups[1].documents.map(\.docId) == ["new", "old"])
  }

  @Test func groupsHoldSearchesTooNewestFirst() {
    let documentHost = UUID()
    let searchHost = UUID()
    let document = SavedDocument(hostId: documentHost, docIndex: "logs", docId: "abc", savedDate: now)
    let older = SavedSearch(hostId: searchHost, searchIndex: "logs-*", query: "older", savedDate: now - 10)
    let newer = SavedSearch(hostId: searchHost, searchIndex: "logs-*", query: "newer", savedDate: now)

    let groups = SavedDocument.grouped([document], searches: [older, newer],
                                       hosts: [(documentHost, "Production"), (searchHost, "Staging")])

    #expect(groups.map(\.hostName) == ["Production", "Staging"])
    #expect(groups[0].searches.isEmpty)
    #expect(groups[1].documents.isEmpty)
    #expect(groups[1].searches.map(\.query) == ["newer", "older"])
    #expect(groups.map(\.count) == [1, 2])
  }

  @Test func filterShowsOneKindAndDropsHostsWithoutIt() {
    let firstHost = UUID()
    let secondHost = UUID()
    let groups = [
      SavedDocumentGroup(id: firstHost, hostName: "Production",
                         documents: [SavedDocument(hostId: firstHost, docIndex: "logs", docId: "a")]),
      SavedDocumentGroup(id: secondHost, hostName: "Staging",
                         documents: [SavedDocument(hostId: secondHost, docIndex: "logs", docId: "b")],
                         searches: [SavedSearch(hostId: secondHost, searchIndex: "logs-*")])
    ]

    #expect(SavedItemFilter.all.apply(groups) == groups)

    let documents = SavedItemFilter.documents.apply(groups)
    #expect(documents.map(\.hostName) == ["Production", "Staging"])
    #expect(documents.allSatisfy { $0.searches.isEmpty })

    let searches = SavedItemFilter.searches.apply(groups)
    #expect(searches.map(\.hostName) == ["Staging"])
    #expect(searches.first?.documents.isEmpty == true)
    #expect(searches.first?.searches.count == 1)
  }

  @Test func periodTitleShowsTheFixedDates() {
    let range = DateInterval(start: now - 3600, end: now)
    let document = SavedDocument(hostId: hostId, docIndex: "logs", docId: "abc", timeRange: range)
    let format = Date.FormatStyle(date: .abbreviated, time: .shortened)
    #expect(document.periodTitle == "\(range.start.formatted(format)) – \(range.end.formatted(format))")
    #expect(SavedDocument(hostId: hostId, docIndex: "logs", docId: "abc").periodTitle == nil)
  }

  // MARK: - Date fields

  @Test func dateFieldKeepsItsPartsInOrder() {
    let field = SquashedFieldsArray(squashedString: "zeta.alpha", fieldParts: ["zeta", "alpha"])
    let saved = SavedDateField(field: field)
    #expect(saved?.parts == ["zeta", "alpha"])

    let squashed = saved?.squashedField()
    #expect(squashed?.squashedString == "zeta.alpha")
    #expect(squashed?.fieldParts == ["zeta", "alpha"])
  }

  @Test func dateFieldWithNoNameIsNil() {
    #expect(SavedDateField(field: SquashedFieldsArray(squashedString: "")) == nil)
  }

  @Test func dateFieldPartsDefaultToTheDottedPath() {
    #expect(SavedDateField(field: "event.created").parts == ["event", "created"])
  }
}
