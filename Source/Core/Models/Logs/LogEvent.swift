// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13, *)
@available(iOS 13.0, *)
public class LogEvent : Object {
  
  @Persisted(primaryKey: true) public var id: UUID = UUID()
  
  // Metadata
  @Persisted public var date : Date = Date.now
  
  // Objects
  @Persisted public var host : LogHostDetails? = nil
  @Persisted public var index : String = ""
  @Persisted public var filter : LogFilter? = nil
  
  // Request
  @Persisted public var jsonReq : String = ""
  @Persisted public var method : String = ""
  
  // Response
  @Persisted public var httpStatus : Int = 0
  @Persisted public var jsonRes : String = ""
  @Persisted public var duration : String = ""
  @Persisted public var error : RealmResponseError? = nil
  @Persisted public var page : Int = 0
  @Persisted public var hitCount : Int = 0

  // Where the request was made from, eg. the Dev Console. Empty for the app's own requests
  @Persisted public var source : String = ""

  // Set when a body was longer than bodyLimit and only its start was kept
  @Persisted public var jsonReqTruncated : Bool = false
  @Persisted public var jsonResTruncated : Bool = false

  public static let devConsoleSource = "Dev Console"

  // The most of each body kept, in UTF-8 bytes. Realm can't store a string over 16 MB,
  // and up to LogDataManager.limit events are kept
  public static let bodyLimit = 1_000_000

  /// The start of `body` that fits in `limit` UTF-8 bytes, without splitting a character,
  /// and whether anything was cut off
  public static func capped(_ body: String, limit: Int = bodyLimit) -> (text: String, truncated: Bool) {
    guard body.utf8.count > limit else { return (body, false) }
    var bytes = 0
    var end = body.startIndex
    for index in body.indices {
      let size = body[index].utf8.count
      if bytes + size > limit { break }
      bytes += size
      end = body.index(after: index)
    }
    return (String(body[..<end]), true)
  }

  /// The request path for a list of requests. The app's request to the root path is its connection test
  public var displayPath: String {
    let path = host?.host?.path ?? ""
    if path.isEmpty {
      return source.isEmpty ? "Connection Test" : "/"
    }
    return path.hasPrefix("/") ? path : "/" + path
  }

  /// What a search or mapping request returned, eg. "12 docs · page 2" or "34 fields"
  public var resultSummary: String? {
    // Dev Console responses aren't read, so their counts are unknown
    guard source.isEmpty || hitCount > 0 else { return nil }
    let path = host?.host?.path ?? ""
    if path.contains("_search") {
      return "\(hitCount.formatted()) docs · page \(max(page, 1))"
    }
    if path.contains("_mapping") {
      return "\(hitCount.formatted()) fields"
    }
    return nil
  }
}


@available(macOS 13, *)
@available(iOS 13.0, *)
public class RealmSearchEvent : Object {
  
  @Persisted(primaryKey: true) public var id: UUID = UUID()
  
  // Metadata
  @Persisted public var date : Date = Date.now
  
  // Objects
  @Persisted public var host : UUID? = nil
  @Persisted public var index : String = ""
  
  // Request
  @Persisted public var filter : RealmFilterObject? = nil
  @Persisted public var query: QueryObject? = nil
  @Persisted public var dateField: RealmSquashedFieldsArray?
  @Persisted public var relativeRange: RealmRelativeRangeFilter?
  @Persisted public var absoluteRange: RealmAbsoluteDateRangeObject?
  @Persisted public var sortObject: RealmSortObject?
  @Persisted public var fieldFilters: List<RealmFieldFilter>
 
}

@available(macOS 13, *)
@available(iOS 15.0, *)
extension RealmSearchEvent {
  /// A recent search on the host and index, holding the filter's query, time period, sort and field filters
  /// in the fields the search history reads.
  public static func make(host: UUID, index: String, filterObject: FilterObject) -> RealmSearchEvent {
    let event = RealmSearchEvent()
    event.date = Date.now
    event.host = host
    event.index = index
    event.query = filterObject.query?.eject()
    if let dateField = filterObject.dateField {
      event.dateField = RealmSquashedFieldsArray(squasedField: dateField)
    }
    event.relativeRange = filterObject.relativeRange?.ejectRealmObject()
    event.absoluteRange = filterObject.absoluteRange?.ejectRealmObject()
    event.sortObject = filterObject.sort?.ejectRealmObjet()
    event.fieldFilters.append(objectsIn: filterObject.fieldFilters.map(RealmFieldFilter.init))
    return event
  }
}


@available(macOS 13, *)
@available(iOS 13.0, *)
public class SearchEvent : ObservableObject, Identifiable {

  public var id: UUID = UUID()

  // Metadata
  public var date : Date = Date.now
  
  // Objects
  public var host : UUID? = nil
  public var index : String = ""
  
  // Request
  public var filter : FilterObject? = nil
 
}
