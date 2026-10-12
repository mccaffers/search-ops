// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// A bookmark to one document on a host, with the search it was found in so its values can be searched for later.
/// Only the reference is kept, the document itself is fetched again when it's opened.
public struct SavedDocument: Identifiable, Equatable, Hashable {
  public var id: UUID
  public var hostId: UUID
  /// The concrete index the document is in, eg. `logs-2026.10.10` or a data stream's backing index
  public var docIndex: String
  public var docId: String
  public var title: String
  /// What was searched when it was saved: a pattern, a data view's pattern or a single index
  public var searchIndex: String
  /// The data view the search was made with, if any
  public var dataViewId: UUID?
  public var dateField: SavedDateField?
  /// The search's time period, always fixed dates: a relative period is pinned to when it was saved
  public var timeRange: DateInterval?
  public var savedDate: Date

  public init(id: UUID = UUID(),
              hostId: UUID,
              docIndex: String,
              docId: String,
              title: String = "",
              searchIndex: String = "",
              dataViewId: UUID? = nil,
              dateField: SavedDateField? = nil,
              timeRange: DateInterval? = nil,
              savedDate: Date = Date.now) {
    self.id = id
    self.hostId = hostId
    self.docIndex = docIndex
    self.docId = docId
    self.title = title
    self.searchIndex = searchIndex
    self.dataViewId = dataViewId
    self.dateField = dateField
    self.timeRange = timeRange
    self.savedDate = savedDate
  }

  public var ref: DocumentRef {
    DocumentRef(index: docIndex, id: docId)
  }

  /// The title to show, `index / id` when none was given
  public var displayTitle: String {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? Self.defaultTitle(for: ref) : trimmed
  }

  public static func defaultTitle(for ref: DocumentRef) -> String {
    "\(ref.index) / \(ref.id)"
  }

  /// The saved time period, eg. "9 Oct 2026 at 14:00 – 10 Oct 2026 at 14:00", nil without one
  public var periodTitle: String? {
    timeRange.map { DateRangeSnapshot.absolute(from: $0.start, to: $0.end, fromNow: false, toNow: false).title }
  }

  /// Documents and searches grouped under their hosts, in the order the hosts are given, each list newest first.
  /// Those of a host that isn't given are left out.
  public static func grouped(_ documents: [SavedDocument],
                             searches: [SavedSearch] = [],
                             hosts: [(id: UUID, name: String)]) -> [SavedDocumentGroup] {
    let documentsByHost = Dictionary(grouping: documents, by: \.hostId)
    let searchesByHost = Dictionary(grouping: searches, by: \.hostId)
    return hosts.compactMap { host in
      let documents = documentsByHost[host.id] ?? []
      let searches = searchesByHost[host.id] ?? []
      guard !documents.isEmpty || !searches.isEmpty else { return nil }
      return SavedDocumentGroup(id: host.id,
                                hostName: host.name,
                                documents: documents.sorted { $0.savedDate > $1.savedDate },
                                searches: searches.sorted { $0.savedDate > $1.savedDate })
    }
  }

  /// A document found by searching `searchIndex` on a host, saved with that search's date field and time period.
  /// A relative period such as "Last 24 hours" becomes the fixed dates it covered at `now`, so later searches still
  /// include the document.
  public static func make(hostId: UUID,
                          ref: DocumentRef,
                          searchIndex: String,
                          dataView: DataView?,
                          dateField: SquashedFieldsArray?,
                          dateRange: DateRangeSnapshot?,
                          now: Date = Date.now) -> SavedDocument {
    let field = dateField.flatMap { SavedDateField(field: $0) }
    return SavedDocument(hostId: hostId,
                         docIndex: ref.index,
                         docId: ref.id,
                         searchIndex: searchIndex,
                         dataViewId: dataView?.id,
                         dateField: field,
                         // A period means nothing without a field to apply it to
                         timeRange: field == nil ? nil : fixedRange(dateRange, now: now),
                         savedDate: now)
  }

  /// The fixed dates a time period covers at `now`, nil when there's no period
  public static func fixedRange(_ snapshot: DateRangeSnapshot?, now: Date = Date.now) -> DateInterval? {
    switch snapshot {
    case .none:
      return nil
    case .relative(let value, let period):
      let seconds = DateTools.calculateSecondsByPeriod(value: value, period: period)
      return interval(now - seconds, now)
    case .absolute(let from, let to, let fromNow, let toNow):
      return interval(fromNow ? now : from, toNow ? now : to)
    }
  }

  private static func interval(_ from: Date, _ to: Date) -> DateInterval {
    from <= to ? DateInterval(start: from, end: to) : DateInterval(start: to, end: from)
  }
}

/// Which saved items the Saved tab shows
public enum SavedItemFilter: String, CaseIterable {
  case all
  case documents
  case searches

  public var title: String {
    switch self {
    case .all: return "All"
    case .documents: return "Documents"
    case .searches: return "Searches"
    }
  }

  /// The groups with only this kind of item, leaving out hosts that then have none
  public func apply(_ groups: [SavedDocumentGroup]) -> [SavedDocumentGroup] {
    switch self {
    case .all:
      return groups
    case .documents:
      return groups.compactMap { group in
        group.documents.isEmpty ? nil : SavedDocumentGroup(id: group.id, hostName: group.hostName, documents: group.documents)
      }
    case .searches:
      return groups.compactMap { group in
        group.searches.isEmpty ? nil : SavedDocumentGroup(id: group.id, hostName: group.hostName, documents: [],
                                                          searches: group.searches)
      }
    }
  }
}

/// One host's saved documents and searches
public struct SavedDocumentGroup: Identifiable, Equatable {
  /// The host's id
  public let id: UUID
  public let hostName: String
  public let documents: [SavedDocument]
  public var searches: [SavedSearch] = []

  public var count: Int { documents.count + searches.count }
}

/// A date field as saved, keeping its path parts in order
public struct SavedDateField: Equatable, Hashable {
  public var field: String
  public var parts: [String]
  public var type: String

  public init(field: String, parts: [String] = [], type: String = "") {
    self.field = field
    self.parts = parts.isEmpty ? field.components(separatedBy: ".") : parts
    self.type = type
  }

  /// nil for a field with no name
  public init?(field: SquashedFieldsArray) {
    guard !field.squashedString.isEmpty else { return nil }
    self.init(field: field.squashedString, parts: field.fieldParts, type: field.type)
  }

  public func squashedField() -> SquashedFieldsArray {
    let squashed = SquashedFieldsArray(squashedString: field, fieldParts: parts)
    squashed.type = type
    return squashed
  }
}

public enum SavedDocumentError: Error, Equatable {
  case missingReference
  case notFound
  case storageUnavailable

  public var message: String {
    switch self {
    case .missingReference:
      return "This document has no index or id to save."
    case .notFound:
      return "This saved document no longer exists."
    case .storageUnavailable:
      return "The local database isn't available."
    }
  }
}
