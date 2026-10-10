// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
@available(iOS 15.0, *)

public class FilterObject: ObservableObject {
  
  public init(id: UUID = UUID(),
              query: QueryObject? = nil,
              dateField: SquashedFieldsArray? = nil,
              relativeRange: RelativeRangeFilter? = nil,
              absoluteRange: AbsoluteDateRangeObject? = nil,
              sort: SortObject? = nil) {
    self.query = query
    self.dateField = dateField
    self.relativeRange = relativeRange
    self.absoluteRange = absoluteRange
    self.sort = sort
  }
  
  @Published public var id: UUID = UUID()
  @Published public var query: QueryObject? = nil {
    didSet {
      id = UUID()
    }
  }
  @Published public var dateField: SquashedFieldsArray? = nil  {
    didSet {
      id = UUID()
    }
  }
  
  @Published public var sort: SortObject? = nil  {
    didSet {
      id = UUID()
    }
  }
  
  @Published public var relativeRange: RelativeRangeFilter? = nil
  {
    didSet {
      id = UUID()
    }
  }
  @Published public var absoluteRange: AbsoluteDateRangeObject? = nil
  {
    didSet {
      id = UUID()
    }
  }
  /// Field value filters shown as chips under the search box. Each change assigns a new array,
  /// so observers hear about it once.
  @Published public var fieldFilters: [FieldFilter] = [] {
    didSet {
      id = UUID()
    }
  }
  
  public func ejectRealmObject()  -> RealmFilterObject {
    let realmFilter = RealmFilterObject()
    
    if let dateField = self.dateField {
      realmFilter.dateField = RealmSquashedFieldsArray(squasedField: dateField)
    }
    
    if let queryObj = self.query {
      realmFilter.query = queryObj.eject()
    }
    
    if let relativeRange = self.relativeRange {
      realmFilter.relativeRange = relativeRange.ejectRealmObject()
    }
    
    if let absoluteRange = self.absoluteRange {
      realmFilter.absoluteRange = absoluteRange.ejectRealmObject()
    }
    
    return realmFilter
  }
  
  /// Identifies the selected time period, so callers can tell whether it changed.
  /// The absolute range is mutated in place, so its values are compared rather than its identity.
  public var dateRangeSignature: String {
    if let relativeRange = relativeRange {
      return "relative:\(relativeRange.value):\(relativeRange.period.rawValue)"
    }
    if let absoluteRange = absoluteRange {
      return "absolute:\(absoluteRange.from.timeIntervalSince1970):\(absoluteRange.fromNow):"
        + "\(absoluteRange.to.timeIntervalSince1970):\(absoluteRange.toNow)"
    }
    return "none"
  }
  
  public func clear(){
    query = nil
    dateField = nil
    relativeRange = nil
    sort = nil
    absoluteRange = nil
    fieldFilters = []
  }
  
  public func resetIndexSpecificFilters() {
    dateField = nil
    sort = nil
    relativeRange = nil
    absoluteRange = nil
  }
  
  /// A copy of the time period, or nil when none is set. Copied because the absolute range is mutated in place.
  public func snapshotDateRange() -> DateRangeSnapshot? {
    if let relativeRange = relativeRange {
      return .relative(value: relativeRange.value, period: relativeRange.period)
    }
    if let absoluteRange = absoluteRange {
      return .absolute(from: absoluteRange.from, to: absoluteRange.to,
                       fromNow: absoluteRange.fromNow, toNow: absoluteRange.toNow)
    }
    return nil
  }
  
  /// Puts back a time period taken with snapshotDateRange.
  public func restore(_ snapshot: DateRangeSnapshot) {
    switch snapshot {
    case .relative(let value, let period):
      absoluteRange = nil
      relativeRange = RelativeRangeFilter(period: period, value: value)
    case .absolute(let from, let to, let fromNow, let toNow):
      relativeRange = nil
      let range = AbsoluteDateRangeObject(from: from, to: to)
      range.fromNow = fromNow
      range.toNow = toNow
      absoluteRange = range
    }
  }
  
  /// Filters on the field's value, or turns on and updates the filter already there for it.
  public func addFieldFilter(field: String, value: String, negated: Bool = false) {
    fieldFilters = fieldFilters.adding(field: field, value: value, negated: negated)
  }
  
  public func removeFieldFilter(_ id: UUID) {
    fieldFilters = fieldFilters.filter { $0.id != id }
  }
  
  /// Switches the filter between keeping and excluding its value.
  public func toggleFieldFilterNegated(_ id: UUID) {
    fieldFilters = fieldFilters.updating(id) { $0.negated.toggle() }
  }
  
  /// Leaves the filter out of the search, or puts it back.
  public func toggleFieldFilterDisabled(_ id: UUID) {
    fieldFilters = fieldFilters.updating(id) { $0.disabled.toggle() }
  }
  
  /// Removes every field filter. They belong to an index's fields, so this goes with choosing another
  /// index, data view or host. It isn't part of `resetIndexSpecificFilters`, which also runs on changing
  /// the date field.
  public func clearFieldFilters() {
    if !fieldFilters.isEmpty {
      fieldFilters = []
    }
  }
  
  /// Searches between two fixed dates, replacing any relative period.
  public func setAbsoluteRange(from: Date, to: Date) {
    relativeRange = nil
    absoluteRange = AbsoluteDateRangeObject(from: from, to: to)
  }
  
}

/// A time period saved so it can be put back, eg. after zooming into the search histogram.
public enum DateRangeSnapshot: Equatable {
  case relative(value: Double, period: SearchDateTimePeriods)
  case absolute(from: Date, to: Date, fromNow: Bool, toNow: Bool)
  
  /// eg. Last hour, Last 6 Months, or 5 Oct 2026 at 20:21 – Now
  public var title: String {
    switch self {
    case .relative(let value, let period):
      if value == 1 {
        return "Last " + String(period.rawValue.dropLast()).lowercased()
      }
      return "Last \(value.formatted()) \(period.rawValue)"
    case .absolute(let from, let to, let fromNow, let toNow):
      let format = Date.FormatStyle(date: .abbreviated, time: .shortened)
      return "\(fromNow ? "Now" : from.formatted(format)) – \(toNow ? "Now" : to.formatted(format))"
    }
  }
}
