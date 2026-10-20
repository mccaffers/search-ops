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

struct SavedSearchTests {

  let hostId = UUID()
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  private func field(_ name: String, type: String = "", visible: Bool = false) -> SquashedFieldsArray {
    let field = SquashedFieldsArray(squashedString: name, fieldParts: name.components(separatedBy: "."))
    field.type = type
    field.visible = visible
    return field
  }

  private func filterObject() -> FilterObject {
    let filterObject = FilterObject()
    filterObject.dateField = field("@timestamp", type: "date")
    filterObject.relativeRange = RelativeRangeFilter(period: .Hours, value: 2)
    let query = QueryObject()
    query.values.append(QueryFilterObject(string: "status:500"))
    filterObject.query = query
    filterObject.sort = SortObject(order: .Ascending, field: field("cpu0", type: "float"))
    filterObject.addFieldFilter(field: "host.name", value: "live-trading")
    filterObject.addFieldFilter(field: "cpu1", value: "0", negated: true)
    return filterObject
  }

  // MARK: - Making a saved search

  @Test func makeKeepsEverythingAboutTheSearch() {
    let view = DataView(hostId: hostId, name: "Trading", pattern: "live-trading-*")

    let search = SavedSearch.make(hostId: hostId,
                                  title: "Errors",
                                  searchIndex: "live-trading-*",
                                  dataView: view,
                                  filterObject: filterObject(),
                                  selectedFields: ["cpu0", "cpu1"],
                                  now: now)

    #expect(search.hostId == hostId)
    #expect(search.title == "Errors")
    #expect(search.searchIndex == "live-trading-*")
    #expect(search.dataViewId == view.id)
    #expect(search.dateField == SavedDateField(field: "@timestamp", parts: ["@timestamp"], type: "date"))
    #expect(search.period == .relative(value: 2, period: .Hours))
    #expect(search.query == "status:500")
    #expect(search.fieldFilters.map(\.field) == ["host.name", "cpu1"])
    #expect(search.fieldFilters.map(\.negated) == [false, true])
    #expect(search.selectedFields == ["cpu0", "cpu1"])
    #expect(search.sortField?.field == "cpu0")
    #expect(search.sortOrder == .Ascending)
    #expect(search.savedDate == now)
  }

  @Test func makeWithoutADateFieldOrQuery() {
    let filterObject = FilterObject()
    filterObject.relativeRange = RelativeRangeFilter(period: .Hours, value: 2)
    let query = QueryObject()
    query.values.append(QueryFilterObject(string: "*"))
    filterObject.query = query

    let search = SavedSearch.make(hostId: hostId, searchIndex: "orders", dataView: nil,
                                  filterObject: filterObject, selectedFields: [], now: now)

    #expect(search.dateField == nil)
    #expect(search.period == nil)
    #expect(search.query == "")
    #expect(search.sortField == nil)
    #expect(search.sortOrder == .Descending)
    #expect(search.displayTitle == "orders")
  }

  @Test func aRelativePeriodStaysRelative() {
    let search = SavedSearch.make(hostId: hostId, searchIndex: "logs-*", dataView: nil,
                                  filterObject: filterObject(), selectedFields: [], now: now)
    #expect(search.isPeriodLive)
    #expect(search.periodTitle == "Last 2 Hours")
  }

  @Test func pinningFixesARelativePeriodToTheDatesItCoversNow() {
    let search = SavedSearch.make(hostId: hostId, searchIndex: "logs-*", dataView: nil,
                                  filterObject: filterObject(), selectedFields: [], pinPeriod: true, now: now)
    #expect(search.period == .absolute(from: now - 7200, to: now, fromNow: false, toNow: false))
    #expect(!search.isPeriodLive)
  }

  @Test func aPeriodEndingNowStaysLiveUnlessPinned() {
    let filterObject = filterObject()
    let from = now - 3600
    filterObject.restore(.absolute(from: from, to: Date.distantPast, fromNow: false, toNow: true))

    let live = SavedSearch.make(hostId: hostId, searchIndex: "logs-*", dataView: nil,
                                filterObject: filterObject, selectedFields: [], now: now)
    let pinned = SavedSearch.make(hostId: hostId, searchIndex: "logs-*", dataView: nil,
                                  filterObject: filterObject, selectedFields: [], pinPeriod: true, now: now)

    #expect(live.period == .absolute(from: from, to: Date.distantPast, fromNow: false, toNow: true))
    #expect(live.isPeriodLive)
    #expect(pinned.period == .absolute(from: from, to: now, fromNow: false, toNow: false))
  }

  @Test func pinningFixedDatesKeepsThem() {
    let period = DateRangeSnapshot.absolute(from: now - 60, to: now, fromNow: false, toNow: false)
    #expect(SavedSearch.savedPeriod(period, pinned: true, now: now + 999) == period)
    #expect(SavedSearch.savedPeriod(nil, pinned: true, now: now) == nil)
  }

  @Test func defaultTitleSummarisesTheSearch() {
    #expect(SavedSearch.defaultTitle(query: "status:500", index: "logs-*", filterCount: 0) == "status:500")
    #expect(SavedSearch.defaultTitle(query: " ", index: "logs-*", filterCount: 1) == "logs-* · 1 filter")
    #expect(SavedSearch.defaultTitle(query: "*", index: "logs-*", filterCount: 3) == "logs-* · 3 filters")
  }

  // MARK: - Running it again

  @Test func requestRebuildsTheSearch() throws {
    let range = DateInterval(start: now - 600, end: now)
    let search = SavedSearch(hostId: hostId,
                             searchIndex: "live-trading-*",
                             dateField: SavedDateField(field: "@timestamp", type: "date"),
                             period: .absolute(from: range.start, to: range.end, fromNow: false, toNow: false),
                             query: "status:500",
                             fieldFilters: [FieldFilter(field: "cpu1", value: "0", negated: true, disabled: true)],
                             selectedFields: ["cpu1", "cpu0"],
                             sortField: SavedDateField(field: "cpu0", type: "float"),
                             sortOrder: .Ascending)

    let request = search.request(dataView: nil)

    #expect(request.hostId == hostId)
    #expect(request.index == "live-trading-*")
    #expect(request.dataView == nil)
    #expect(request.selectedFields == ["cpu1", "cpu0"])
    let filter = request.filterObject
    #expect(filter.dateField?.squashedString == "@timestamp")
    #expect(filter.relativeRange == nil)
    let absolute = try #require(filter.absoluteRange)
    #expect(absolute.from == range.start)
    #expect(absolute.to == range.end)
    #expect(filter.query?.values.first?.string == "status:500")
    #expect(filter.query?.values.count == 1)
    #expect(filter.fieldFilters.count == 1)
    #expect(filter.fieldFilters.first?.negated == true)
    #expect(filter.fieldFilters.first?.disabled == true)
    #expect(filter.sort?.field.squashedString == "cpu0")
    #expect(filter.sort?.order == .Ascending)
  }

  @Test func requestKeepsARelativePeriodRelative() throws {
    let search = SavedSearch(hostId: hostId,
                             searchIndex: "logs-*",
                             dateField: SavedDateField(field: "@timestamp", type: "date"),
                             period: .relative(value: 1, period: .Hours))

    let filter = search.request(dataView: nil).filterObject

    #expect(filter.absoluteRange == nil)
    let relative = try #require(filter.relativeRange)
    #expect(relative.value == 1)
    #expect(relative.period == .Hours)
  }

  @Test func requestKeepsAPeriodEndingNow() throws {
    let from = now - 3600
    let search = SavedSearch(hostId: hostId,
                             searchIndex: "logs-*",
                             dateField: SavedDateField(field: "@timestamp", type: "date"),
                             period: .absolute(from: from, to: now, fromNow: false, toNow: true))

    let absolute = try #require(search.request(dataView: nil).filterObject.absoluteRange)

    #expect(absolute.from == from)
    #expect(absolute.toNow)
    #expect(!absolute.fromNow)
  }

  @Test func requestWithoutAQuerySearchesEverything() {
    let search = SavedSearch(hostId: hostId, searchIndex: "logs-*")
    let request = search.request(dataView: nil)
    #expect(request.filterObject.query == nil)
    #expect(request.filterObject.sort == nil)
    #expect(request.filterObject.dateField == nil)
    #expect(request.selectedFields == [])
  }

  @Test func requestUsesTheDataViewWhileItExists() {
    let view = DataView(hostId: hostId, name: "Trading", pattern: "live-trading-*,backtest-*")
    let search = SavedSearch(hostId: hostId, searchIndex: "live-trading-*", dataViewId: view.id)

    #expect(search.request(dataView: view).index == "live-trading-*,backtest-*")
    #expect(search.request(dataView: view).dataView == view)
    // Once it's deleted, the pattern it had is searched
    #expect(search.request(dataView: nil).index == "live-trading-*")
    #expect(search.request(dataView: nil).dataView == nil)
  }

  // MARK: - Showing its columns

  @Test func applySelectedFieldsShowsExactlyThoseFields() {
    let date = field("@timestamp", type: "date", visible: true)
    let cpu0 = field("cpu0", visible: true)
    let cpu1 = field("cpu1")
    let cpu2 = field("cpu2")
    var fields = [date, cpu0, cpu1, cpu2]
    var onlyVisibleFields = [date, cpu0]

    SavedSearch.applySelectedFields(["cpu2", "cpu1", "message"],
                                    dateField: "@timestamp",
                                    fields: &fields,
                                    onlyVisibleFields: &onlyVisibleFields)

    #expect(date.visible, "The date field keeps its own column")
    #expect(!cpu0.visible)
    #expect(cpu1.visible)
    #expect(cpu2.visible)
    // A field that's not in the mapping is added, as ticking it in the Document panel would
    let message = fields.first { $0.squashedString == "message" }
    #expect(message?.visible == true)
    #expect(Set(onlyVisibleFields.map(\.squashedString)).isSuperset(of: ["cpu1", "cpu2", "message"]))
  }

  @Test func applyingNoSelectedFieldsHidesEveryColumnButTheDate() {
    let date = field("@timestamp", type: "date", visible: true)
    let cpu0 = field("cpu0", visible: true)
    var fields = [date, cpu0]
    var onlyVisibleFields = [cpu0]

    SavedSearch.applySelectedFields([], dateField: "@timestamp", fields: &fields, onlyVisibleFields: &onlyVisibleFields)

    #expect(date.visible)
    #expect(!cpu0.visible)
    #expect(fields.count == 2)
  }

  // MARK: - Telling whether it has changed

  private func state(_ filterObject: FilterObject,
                     index: String = "live-trading-*",
                     dataViewId: UUID? = nil,
                     columns: [String] = ["cpu0", "cpu1"]) -> SavedSearchState {
    SavedSearchState(searchIndex: index, dataViewId: dataViewId, filterObject: filterObject, selectedFields: columns)
  }

  @Test func theSameSearchHasNoChanges() {
    let filterObject = filterObject()
    #expect(state(filterObject).changes(from: state(filterObject)).isEmpty)
  }

  @Test func aRelativePeriodIsNotAChangeStraightAfterSaving() {
    // Pinning the saved copy to fixed dates leaves the screen with its relative period
    let filterObject = filterObject()
    let baseline = state(filterObject)
    _ = SavedSearch.make(hostId: hostId, searchIndex: "live-trading-*", dataView: nil,
                         filterObject: filterObject, selectedFields: ["cpu0", "cpu1"], pinPeriod: true, now: now)
    #expect(state(filterObject).changes(from: baseline).isEmpty)
  }

  @Test func eachPartIsAChange() {
    let baseline = state(filterObject())

    let query = filterObject()
    query.query?.values.first?.string = "status:404"
    #expect(state(query).changes(from: baseline) == [.query])

    let disabledChip = filterObject()
    disabledChip.toggleFieldFilterDisabled(disabledChip.fieldFilters[0].id)
    #expect(state(disabledChip).changes(from: baseline) == [.filters])

    #expect(state(filterObject(), columns: ["cpu1", "cpu0"]).changes(from: baseline) == [.columns])
    #expect(state(filterObject(), index: "backtest-*").changes(from: baseline) == [.index])
    #expect(state(filterObject(), dataViewId: UUID()).changes(from: baseline) == [.index])

    let sort = filterObject()
    sort.sort?.order = .Descending
    #expect(state(sort).changes(from: baseline) == [.sort])

    let period = filterObject()
    period.relativeRange = RelativeRangeFilter(period: .Hours, value: 3)
    #expect(state(period).changes(from: baseline) == [.period])

    let dateField = filterObject()
    dateField.dateField = field("event.created", type: "date")
    #expect(state(dateField).changes(from: baseline) == [.dateField])
  }

  @Test func filtersInAnotherOrderAreNotAChange() {
    let reordered = filterObject()
    reordered.fieldFilters = reordered.fieldFilters.reversed()
    #expect(state(reordered).changes(from: state(filterObject())).isEmpty)
  }

  @Test func anEmptyQueryAndEverythingAreTheSame() {
    let star = FilterObject()
    let query = QueryObject()
    query.values.append(QueryFilterObject(string: " * "))
    star.query = query
    #expect(state(star).changes(from: state(FilterObject())).isEmpty)
  }

  @Test func aPeriodWithoutADateFieldIsIgnored() {
    let withPeriod = FilterObject()
    withPeriod.relativeRange = RelativeRangeFilter(period: .Hours, value: 3)
    #expect(state(withPeriod).changes(from: state(FilterObject())).isEmpty)
  }

  @Test func aSavedSearchOpenedAgainHasNoChanges() {
    let range = DateInterval(start: now - 600, end: now)
    let search = SavedSearch(hostId: hostId,
                             searchIndex: "live-trading-*",
                             dateField: SavedDateField(field: "@timestamp", type: "date"),
                             period: .absolute(from: range.start, to: range.end, fromNow: false, toNow: false),
                             query: "status:500",
                             fieldFilters: [FieldFilter(field: "cpu1", value: "0")],
                             selectedFields: ["cpu1"],
                             sortField: SavedDateField(field: "cpu0"),
                             sortOrder: .Ascending)
    let request = search.request(dataView: nil)

    #expect(request.savedSearch?.id == search.id)
    let baseline = SavedSearchState(request: request)
    let onScreen = SavedSearchState(searchIndex: request.index, dataViewId: nil,
                                    filterObject: request.filterObject, selectedFields: ["cpu1"])
    #expect(onScreen.changes(from: baseline).isEmpty)
    #expect(baseline.period == .absolute(from: range.start, to: range.end, fromNow: false, toNow: false))
  }

  /// As iOS opens a saved search: its fields are picked from the index's mapping, and the date field isn't one of them
  @Test func aSavedSearchOpenedOnIOSWithItsFieldsPickedHasNoChanges() {
    let search = SavedSearch(hostId: hostId,
                             searchIndex: "logs-*",
                             dateField: SavedDateField(field: "@timestamp", type: "date"),
                             period: .relative(value: 24, period: .Hours),
                             query: "status:500",
                             selectedFields: ["service", "message"])
    let request = search.request(dataView: nil)
    let baseline = SavedSearchState(request: request)

    var mapping = [field("@timestamp", type: "date"), field("message"), field("service"), field("status")]
    var picked = [SquashedFieldsArray]()
    SavedSearch.applySelectedFields(request.selectedFields ?? [], dateField: "@timestamp",
                                    fields: &mapping, onlyVisibleFields: &picked)
    let keys = picked.map(\.squashedString).filter { $0 != request.filterObject.dateField?.squashedString }
    let onScreen = SavedSearchState(searchIndex: request.index, dataViewId: nil,
                                    filterObject: request.filterObject, selectedFields: keys)

    #expect(keys == ["service", "message"])
    #expect(onScreen.changes(from: baseline).isEmpty)

    // Before the fields are picked none are shown, which would read as a change
    let beforePicking = SavedSearchState(searchIndex: request.index, dataViewId: nil,
                                         filterObject: request.filterObject, selectedFields: [])
    #expect(beforePicking.changes(from: baseline) == [.columns])
  }

  @Test func columnWidthsAreSavedRunAgainAndCountAsAChange() {
    let widths = ["date:date": 512.5, "field:dayClose": 82]
    let search = SavedSearch.make(hostId: hostId, searchIndex: "volatility", dataView: nil,
                                  filterObject: filterObject(), selectedFields: ["dayClose"],
                                  columnWidths: widths, now: now)
    #expect(search.columnWidths == widths)

    let request = search.request(dataView: nil)
    #expect(request.columnWidths == widths)
    let baseline = SavedSearchState(request: request)
    #expect(baseline.columnWidths == widths)

    let resized = SavedSearchState(searchIndex: request.index, dataViewId: nil, filterObject: request.filterObject,
                                   selectedFields: ["dayClose"], columnWidths: ["date:date": 300])
    #expect(resized.changes(from: baseline) == [.columnWidths])
    #expect(SavedSearchState.changesLabel([.columnWidths]) == "Changed: column widths")
  }

  @Test func aRelativeSavedSearchOpenedAgainHasNoChanges() {
    let saved = SavedSearch.make(hostId: hostId, searchIndex: "live-trading-*", dataView: nil,
                                 filterObject: filterObject(), selectedFields: ["cpu0"], now: now)
    let request = saved.request(dataView: nil)

    let baseline = SavedSearchState(request: request)
    let onScreen = SavedSearchState(searchIndex: request.index, dataViewId: nil,
                                    filterObject: request.filterObject, selectedFields: ["cpu0"])

    #expect(baseline.period == .relative(value: 2, period: .Hours))
    #expect(onScreen.changes(from: baseline).isEmpty)
  }

  @Test func switchingBetweenRelativeAndFixedDatesIsAPeriodChange() {
    #expect(SavedSearchState.changes([], pinningChanged: true) == [.period])
    #expect(SavedSearchState.changes([.query, .sort], pinningChanged: true) == [.query, .sort, .period])
    #expect(SavedSearchState.changes([.query, .period], pinningChanged: true) == [.query, .period])
    #expect(SavedSearchState.changes([.query], pinningChanged: false) == [.query])
  }

  @Test func aSearchSavedWithFixedDatesForARelativePeriodIsPinned() {
    let filterObject = filterObject()
    let baseline = state(filterObject)
    let pinned = SavedSearch.make(hostId: hostId, searchIndex: "live-trading-*", dataView: nil,
                                  filterObject: filterObject, selectedFields: [], pinPeriod: true, now: now)
    let relative = SavedSearch.make(hostId: hostId, searchIndex: "live-trading-*", dataView: nil,
                                    filterObject: filterObject, selectedFields: [], now: now)

    #expect(SavedSearchLink.isPinned(pinned, baseline: baseline))
    #expect(!SavedSearchLink.isPinned(relative, baseline: baseline))
    // Opened from the Saved tab, the screen has the same fixed dates, which weren't pinned from anything
    #expect(!SavedSearchLink.isPinned(pinned, baseline: SavedSearchState(request: pinned.request(dataView: nil))))
  }

  @Test func changesLabelListsTheParts() {
    #expect(SavedSearchState.changesLabel([]) == "No changes")
    #expect(SavedSearchState.changesLabel([.query, .columns, .period]) == "Changed: query, columns, time period")
  }

  @Test func copyTitleAddsCopy() {
    #expect(SavedSearch.copyTitle(of: "Errors") == "Errors copy")
  }
}
