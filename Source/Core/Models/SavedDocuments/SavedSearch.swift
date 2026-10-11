// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// A search kept in the Saved tab: what was searched, its query, field filters, time period and the fields shown
/// as columns, so it can be run again exactly.
public struct SavedSearch: Identifiable, Equatable, Hashable {
  public var id: UUID
  public var hostId: UUID
  public var title: String
  /// What was searched: a pattern, a data view's pattern or a single index
  public var searchIndex: String
  /// The data view the search was made with, if any
  public var dataViewId: UUID?
  public var dateField: SavedDateField?
  /// Always fixed dates: a relative period is pinned to when it was saved
  public var timeRange: DateInterval?
  /// The query box, eg. `status:500`. Empty for every document.
  public var query: String
  public var fieldFilters: [FieldFilter]
  /// The fields shown as columns, in order, not counting the date field. Empty shows each whole document.
  public var selectedFields: [String]
  /// Widths set by dragging a column border, by column, eg. "field:dayClose". Columns not here size themselves.
  public var columnWidths: [String: Double]
  /// Reuses the date field's shape for any field the search was sorted by
  public var sortField: SavedDateField?
  public var sortOrder: SortOrderEnum
  public var savedDate: Date
  /// When it was last updated from the Search tab, nil if never
  public var updatedDate: Date?

  public init(id: UUID = UUID(),
              hostId: UUID,
              title: String = "",
              searchIndex: String,
              dataViewId: UUID? = nil,
              dateField: SavedDateField? = nil,
              timeRange: DateInterval? = nil,
              query: String = "",
              fieldFilters: [FieldFilter] = [],
              selectedFields: [String] = [],
              columnWidths: [String: Double] = [:],
              sortField: SavedDateField? = nil,
              sortOrder: SortOrderEnum = .Descending,
              savedDate: Date = Date.now,
              updatedDate: Date? = nil) {
    self.id = id
    self.hostId = hostId
    self.title = title
    self.searchIndex = searchIndex
    self.dataViewId = dataViewId
    self.dateField = dateField
    self.timeRange = timeRange
    self.query = query
    self.fieldFilters = fieldFilters
    self.selectedFields = selectedFields
    self.columnWidths = columnWidths
    self.sortField = sortField
    self.sortOrder = sortOrder
    self.savedDate = savedDate
    self.updatedDate = updatedDate
  }

  /// The title to show, a summary of the search when none was given
  public var displayTitle: String {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? Self.defaultTitle(query: query, index: searchIndex, filterCount: fieldFilters.count) : trimmed
  }

  /// eg. `status:500 · 2 filters`, or the index when there's no query
  public static func defaultTitle(query: String, index: String, filterCount: Int) -> String {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    var title = trimmed.isEmpty || trimmed == "*" ? index : trimmed
    if filterCount > 0 {
      title += " · \(filterCount) \(filterCount == 1 ? "filter" : "filters")"
    }
    return title
  }

  /// The name suggested when saving a copy, eg. "Errors copy"
  public static func copyTitle(of title: String) -> String {
    "\(title) copy"
  }

  /// The saved time period, eg. "9 Oct 2026 at 14:00 – 10 Oct 2026 at 14:00", nil without one
  public var periodTitle: String? {
    timeRange.map { DateRangeSnapshot.absolute(from: $0.start, to: $0.end, fromNow: false, toNow: false).title }
  }

  /// The search as it stands, with a relative period pinned to the fixed dates it covers at `now`
  public static func make(hostId: UUID,
                          title: String = "",
                          searchIndex: String,
                          dataView: DataView?,
                          filterObject: FilterObject,
                          selectedFields: [String],
                          columnWidths: [String: Double] = [:],
                          now: Date = Date.now) -> SavedSearch {
    let dateField = filterObject.dateField.flatMap { SavedDateField(field: $0) }
    let query = filterObject.query?.values.first?.string ?? ""
    return SavedSearch(hostId: hostId,
                       title: title,
                       searchIndex: searchIndex,
                       dataViewId: dataView?.id,
                       dateField: dateField,
                       // A period means nothing without a field to apply it to
                       timeRange: dateField == nil ? nil : SavedDocument.fixedRange(filterObject.snapshotDateRange(), now: now),
                       query: query == "*" ? "" : query,
                       fieldFilters: filterObject.fieldFilters,
                       selectedFields: selectedFields,
                       columnWidths: columnWidths,
                       sortField: filterObject.sort.flatMap { SavedDateField(field: $0.field) },
                       sortOrder: filterObject.sort?.order ?? .Descending,
                       savedDate: now)
  }

  /// The search to run in the Search tab: on the data view while it still exists (`dataView` is the view looked up
  /// by `dataViewId`, nil once it's deleted), otherwise on the saved pattern or index
  public func request(dataView: DataView?) -> SearchHandoffRequest {
    let target = SavedDocumentSearch.target(hostId: hostId,
                                            dataViewId: dataViewId,
                                            searchIndex: searchIndex,
                                            fallback: searchIndex,
                                            dataView: dataView)
    let filterObject = FilterObject()
    if let dateField = dateField {
      filterObject.dateField = dateField.squashedField()
      if let range = timeRange {
        filterObject.absoluteRange = AbsoluteDateRangeObject(from: range.start, to: range.end)
      }
    }
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      let queryObject = QueryObject()
      queryObject.values.append(QueryFilterObject(string: trimmed))
      filterObject.query = queryObject
    }
    if let sortField = sortField {
      filterObject.sort = SortObject(order: sortOrder, field: sortField.squashedField())
    }
    filterObject.fieldFilters = fieldFilters
    return SearchHandoffRequest(hostId: hostId,
                                index: target.index,
                                dataView: target.dataView,
                                filterObject: filterObject,
                                selectedFields: selectedFields,
                                columnWidths: columnWidths,
                                savedSearch: self)
  }

  /// Shows exactly `keys` as columns: each one is shown, adding fields that aren't in the lists yet, and every
  /// other field is hidden. The date field is left as it is, it has a column of its own.
  public static func applySelectedFields(_ keys: [String],
                                         dateField: String?,
                                         fields: inout [SquashedFieldsArray],
                                         onlyVisibleFields: inout [SquashedFieldsArray]) {
    let wanted = Set(keys)
    for field in fields + onlyVisibleFields where field.squashedString != dateField {
      let visible = wanted.contains(field.squashedString)
      if field.visible != visible {
        field.visible = visible
      }
    }
    for key in keys where key != dateField {
      let field: SquashedFieldsArray
      if let existing = fields.first(where: { $0.squashedString == key }) {
        field = existing
      } else if let existing = onlyVisibleFields.first(where: { $0.squashedString == key }) {
        field = existing
        fields.append(field)
      } else {
        field = SquashedFieldsArray(squashedString: key, fieldParts: key.components(separatedBy: "."))
        fields.append(field)
      }
      field.visible = true
      if !onlyVisibleFields.contains(where: { $0.squashedString == key }) {
        onlyVisibleFields.append(field)
      }
    }
  }
}

/// What a search is made of, as far as saving it goes, to tell whether it has changed since it was saved.
/// The time period is kept as it was set, so a relative period isn't a change just because the saved copy has
/// fixed dates. The page, column widths and results aren't part of it.
public struct SavedSearchState: Equatable {
  public enum Part: String, CaseIterable {
    case index = "index"
    case query = "query"
    case filters = "filters"
    case columns = "columns"
    case columnWidths = "column widths"
    case sort = "sort"
    case dateField = "date field"
    case period = "time period"
  }

  public var index: String
  public var dataViewId: UUID?
  public var query: String
  /// Order doesn't matter, the same chips in another order are the same search
  public var filters: [String]
  public var columns: [String]
  public var columnWidths: [String: Double]
  public var sortField: String?
  public var sortOrder: SortOrderEnum?
  public var dateField: String?
  /// nil without a date field, as a period means nothing without one
  public var period: DateRangeSnapshot?

  public init(searchIndex: String,
              dataViewId: UUID?,
              filterObject: FilterObject,
              selectedFields: [String],
              columnWidths: [String: Double] = [:]) {
    let query = (filterObject.query?.values.first?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let dateField = filterObject.dateField?.squashedString
    self.index = searchIndex.trimmingCharacters(in: .whitespacesAndNewlines)
    self.dataViewId = dataViewId
    self.query = query == "*" ? "" : query
    self.filters = filterObject.fieldFilters
      .map { "\($0.field)\u{0}\($0.value)\u{0}\($0.negated)\u{0}\($0.disabled)" }
      .sorted()
    self.columns = selectedFields
    self.columnWidths = columnWidths
    self.sortField = filterObject.sort?.field.squashedString
    self.sortOrder = filterObject.sort?.order
    self.dateField = dateField
    self.period = dateField == nil ? nil : filterObject.snapshotDateRange()
  }

  /// The search a handoff from the Saved tab starts, before any change is made to it
  public init(request: SearchHandoffRequest) {
    self.init(searchIndex: request.index,
              dataViewId: request.dataView?.id,
              filterObject: request.filterObject,
              selectedFields: request.selectedFields ?? [],
              columnWidths: request.columnWidths ?? [:])
  }

  /// The parts that differ from `baseline`, in a fixed order
  public func changes(from baseline: SavedSearchState) -> [Part] {
    var parts: [Part] = []
    if index != baseline.index || dataViewId != baseline.dataViewId { parts.append(.index) }
    if query != baseline.query { parts.append(.query) }
    if filters != baseline.filters { parts.append(.filters) }
    if columns != baseline.columns { parts.append(.columns) }
    if columnWidths != baseline.columnWidths { parts.append(.columnWidths) }
    if sortField != baseline.sortField || sortOrder != baseline.sortOrder { parts.append(.sort) }
    if dateField != baseline.dateField { parts.append(.dateField) }
    if period != baseline.period { parts.append(.period) }
    return parts
  }

  /// eg. "Changed: query, filters", or "No changes"
  public static func changesLabel(_ parts: [Part]) -> String {
    parts.isEmpty ? "No changes" : "Changed: " + parts.map(\.rawValue).joined(separator: ", ")
  }
}

/// The saved search the Search tab is showing, so saving again can update it
public struct SavedSearchLink: Equatable {
  public let id: UUID
  public var title: String
  /// The search when it was saved, updated or opened
  public var baseline: SavedSearchState

  public init(id: UUID, title: String, baseline: SavedSearchState) {
    self.id = id
    self.title = title
    self.baseline = baseline
  }
}
