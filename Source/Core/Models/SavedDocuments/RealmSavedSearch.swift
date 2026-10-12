// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// A saved search for one host.
/// New columns must be optional or default to a valid empty value, and not be enums:
/// rows that already exist start with the column empty, so no migration code is needed.
public class RealmSavedSearch: Object {

  @Persisted(primaryKey: true) public var id: UUID
  @Persisted(indexed: true) public var hostId: UUID
  @Persisted public var title: String = ""
  @Persisted public var searchIndex: String = ""
  @Persisted public var dataViewId: UUID?
  // "" means no date field
  @Persisted public var dateField: String = ""
  @Persisted public var dateFieldParts: List<String>
  @Persisted public var dateFieldType: String = ""
  // Both set, or neither, for fixed dates or ones that start or end now. Unused for a relative period.
  @Persisted public var rangeFrom: Date?
  @Persisted public var rangeTo: Date?
  @Persisted public var rangeFromNow: Bool = false
  @Persisted public var rangeToNow: Bool = false
  // A relative period, eg. 1 and "Hours". "" means the period is the dates above, as in searches saved before
  // relative periods were kept. A SearchDateTimePeriods raw value, kept as a string so an empty column is valid.
  @Persisted public var relativeValue: Double = 0
  @Persisted public var relativePeriod: String = ""
  @Persisted public var query: String = ""
  // Embedded, so deleting the search deletes its filters
  @Persisted public var fieldFilters: List<RealmFieldFilter>
  @Persisted public var selectedFields: List<String>
  // Embedded, so deleting the search deletes its widths
  @Persisted public var columnWidths: List<RealmColumnWidth>
  // "" means not sorted
  @Persisted public var sortField: String = ""
  @Persisted public var sortFieldParts: List<String>
  @Persisted public var sortFieldType: String = ""
  // A SortOrderEnum raw value, kept as a string so an empty column reads as the default
  @Persisted public var sortOrder: String = SortOrderEnum.Descending.rawValue
  @Persisted public var savedDate: Date = Date.now
  @Persisted public var updatedDate: Date?

  public convenience init(search: SavedSearch) {
    self.init()
    self.id = search.id
    self.hostId = search.hostId
    self.title = search.title
    self.searchIndex = search.searchIndex
    self.dataViewId = search.dataViewId
    if let field = search.dateField {
      self.dateField = field.field
      self.dateFieldParts.append(objectsIn: field.parts)
      self.dateFieldType = field.type
    }
    setPeriod(search.period)
    self.query = search.query
    self.fieldFilters.append(objectsIn: search.fieldFilters.map(RealmFieldFilter.init))
    self.selectedFields.append(objectsIn: search.selectedFields)
    self.columnWidths.append(objectsIn: RealmColumnWidth.list(search.columnWidths))
    if let field = search.sortField {
      self.sortField = field.field
      self.sortFieldParts.append(objectsIn: field.parts)
      self.sortFieldType = field.type
    }
    self.sortOrder = search.sortOrder.rawValue
    self.savedDate = search.savedDate
    self.updatedDate = search.updatedDate
  }

  /// Copies the search's contents, keeping the id, host, title and saved date
  public func apply(_ search: SavedSearch) {
    searchIndex = search.searchIndex
    dataViewId = search.dataViewId
    dateField = search.dateField?.field ?? ""
    dateFieldParts.removeAll()
    dateFieldParts.append(objectsIn: search.dateField?.parts ?? [])
    dateFieldType = search.dateField?.type ?? ""
    setPeriod(search.period)
    query = search.query
    fieldFilters.removeAll()
    fieldFilters.append(objectsIn: search.fieldFilters.map(RealmFieldFilter.init))
    selectedFields.removeAll()
    selectedFields.append(objectsIn: search.selectedFields)
    columnWidths.removeAll()
    columnWidths.append(objectsIn: RealmColumnWidth.list(search.columnWidths))
    sortField = search.sortField?.field ?? ""
    sortFieldParts.removeAll()
    sortFieldParts.append(objectsIn: search.sortField?.parts ?? [])
    sortFieldType = search.sortField?.type ?? ""
    sortOrder = search.sortOrder.rawValue
  }

  private func setPeriod(_ period: DateRangeSnapshot?) {
    rangeFrom = nil
    rangeTo = nil
    rangeFromNow = false
    rangeToNow = false
    relativeValue = 0
    relativePeriod = ""
    switch period {
    case .none:
      break
    case .relative(let value, let unit):
      relativeValue = value
      relativePeriod = unit.rawValue
    case .absolute(let from, let to, let fromNow, let toNow):
      rangeFrom = from
      rangeTo = to
      rangeFromNow = fromNow
      rangeToNow = toNow
    }
  }

  /// The saved period, nil without one or when the stored dates don't make sense
  var period: DateRangeSnapshot? {
    if let unit = SearchDateTimePeriods(rawValue: relativePeriod) {
      return .relative(value: relativeValue, period: unit)
    }
    guard let from = rangeFrom, let to = rangeTo else { return nil }
    // A side that's now has no date of its own to be out of order with
    guard rangeFromNow || rangeToNow || from <= to else { return nil }
    return .absolute(from: from, to: to, fromNow: rangeFromNow, toNow: rangeToNow)
  }

  /// A plain copy that's safe to keep after the object is deleted
  public func eject() -> SavedSearch {
    return SavedSearch(id: id,
                       hostId: hostId,
                       title: title,
                       searchIndex: searchIndex,
                       dataViewId: dataViewId,
                       dateField: dateField.isEmpty ? nil : SavedDateField(field: dateField,
                                                                           parts: Array(dateFieldParts),
                                                                           type: dateFieldType),
                       period: period,
                       query: query,
                       fieldFilters: fieldFilters.map { $0.eject() },
                       selectedFields: Array(selectedFields),
                       columnWidths: Dictionary(columnWidths.map { ($0.column, $0.width) },
                                                uniquingKeysWith: { first, _ in first }),
                       sortField: sortField.isEmpty ? nil : SavedDateField(field: sortField,
                                                                           parts: Array(sortFieldParts),
                                                                           type: sortFieldType),
                       sortOrder: SortOrderEnum(rawValue: sortOrder) ?? .Descending,
                       savedDate: savedDate,
                       updatedDate: updatedDate)
  }
}

/// A column width saved with a search
public class RealmColumnWidth: EmbeddedObject {
  @Persisted public var column: String = ""
  @Persisted public var width: Double = 0

  /// One per column, sorted so the same widths are always stored the same way
  static func list(_ widths: [String: Double]) -> [RealmColumnWidth] {
    widths.keys.sorted().compactMap { key in
      guard let width = widths[key] else { return nil }
      let item = RealmColumnWidth()
      item.column = key
      item.width = width
      return item
    }
  }
}
