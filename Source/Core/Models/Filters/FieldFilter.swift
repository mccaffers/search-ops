// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// A filter on one field's value, shown as a chip under the search box. It's sent apart from the query text,
/// as an exact phrase match the results must have, or must not have when negated.
public struct FieldFilter: Hashable, Identifiable {
  public var id: UUID
  public var field: String
  public var value: String
  /// Excludes documents with the value instead of keeping only them
  public var negated: Bool
  /// Kept as a chip but left out of the search
  public var disabled: Bool

  public init(id: UUID = UUID(), field: String, value: String, negated: Bool = false, disabled: Bool = false) {
    self.id = id
    self.field = field
    self.value = value
    self.negated = negated
    self.disabled = disabled
  }

  /// A filter for a document field's value, or nil when the field has no value or several,
  /// as there's no single value to filter on.
  public static func make(field: String, values: Any, negated: Bool = false) -> FieldFilter? {
    let texts: [String]
    if let strings = values as? [String] {
      texts = strings
    } else if let string = values as? String {
      texts = [string]
    } else {
      return nil
    }
    guard texts.count == 1, let value = texts.first,
          !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }
    return FieldFilter(field: field, value: value, negated: negated)
  }

  /// The text cut to `limit` characters by taking out its middle, so both ends stay readable.
  public static func shortened(_ text: String, limit: Int = 40) -> String {
    guard text.count > limit, limit > 1 else { return text }
    let head = (limit - 1) / 2 + (limit - 1) % 2
    let tail = (limit - 1) / 2
    return String(text.prefix(head)) + "…" + String(text.suffix(tail))
  }

  /// Whether the filter is on the same field and value, whatever its other settings.
  public func matches(field: String, value: String) -> Bool {
    self.field == field && self.value == value
  }
}

/// A field and value, to look up whether something is already filtered on.
public struct FieldFilterKey: Hashable {
  public let field: String
  public let value: String

  public init(field: String, value: String) {
    self.field = field
    self.value = value
  }
}

extension Array where Element == FieldFilter {

  /// Adds a filter for the field's value, turning on one that's already there rather than repeating it,
  /// and setting whether it excludes the value.
  public func adding(field: String, value: String, negated: Bool) -> [FieldFilter] {
    var filters = self
    if let index = filters.firstIndex(where: { $0.matches(field: field, value: value) }) {
      filters[index].negated = negated
      filters[index].disabled = false
    } else {
      filters.append(FieldFilter(field: field, value: value, negated: negated))
    }
    return filters
  }

  /// The filter with the id changed by `change`, or the filters unchanged when it isn't there.
  public func updating(_ id: UUID, _ change: (inout FieldFilter) -> Void) -> [FieldFilter] {
    var filters = self
    if let index = filters.firstIndex(where: { $0.id == id }) {
      change(&filters[index])
    }
    return filters
  }

  /// Whether each field and value with an enabled filter is kept (false) or excluded (true).
  public var enabledValues: [FieldFilterKey: Bool] {
    Dictionary(enabled.map { (FieldFilterKey(field: $0.field, value: $0.value), $0.negated) },
               uniquingKeysWith: { first, _ in first })
  }

  /// The filters that take part in the search.
  public var enabled: [FieldFilter] {
    filter { !$0.disabled }
  }

  /// Whether both hold the same filters, in any order. Ids aren't compared.
  public func hasSameFilters(as other: [FieldFilter]) -> Bool {
    guard count == other.count else { return false }
    func signature(_ filter: FieldFilter) -> String {
      "\(filter.field)\u{0}\(filter.value)\u{0}\(filter.negated)\u{0}\(filter.disabled)"
    }
    return map(signature).sorted() == other.map(signature).sorted()
  }
}

/// A field filter saved with a recent search.
public class RealmFieldFilter: EmbeddedObject {
  @Persisted public var field: String = ""
  @Persisted public var value: String = ""
  @Persisted public var negated: Bool = false
  @Persisted public var disabled: Bool = false

  public convenience init(_ filter: FieldFilter) {
    self.init()
    field = filter.field
    value = filter.value
    negated = filter.negated
    disabled = filter.disabled
  }

  public func eject() -> FieldFilter {
    FieldFilter(field: field, value: value, negated: negated, disabled: disabled)
  }
}
