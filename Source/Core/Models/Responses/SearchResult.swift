// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import OrderedCollections

/// Where a document lives, read from its search hit: the concrete index (not the pattern searched) and its `_id`.
public struct DocumentRef: Hashable, Sendable {
  public let index: String
  public let id: String

  public init(index: String, id: String) {
    self.index = index
    self.id = id
  }

  /// The hit's `_index` and `_id`, or nil when either is missing or empty
  public init?(hit: [String: Any]) {
    guard let index = hit["_index"] as? String, !index.isEmpty,
          let id = hit["_id"] as? String, !id.isEmpty else { return nil }
    self.init(index: index, id: id)
  }
}

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class SearchResult : ObservableObject {
  
  public init(data: [[String : Any]] = [], hitCount:Int = 0, hitCountIsLowerBound: Bool = false, fields : [SquashedFieldsArray] = [], rows: [OrderedDictionary<String, Any>] = [], refs: [DocumentRef?] = [], error: String? = nil, errorTitle: String? = nil) {
    self.data = data
    self.rows = rows
    self.refs = refs
    self.error = error
    self.hitCount = hitCount
    self.hitCountIsLowerBound = hitCountIsLowerBound
    self.fields = fields
    self.errorTitle = errorTitle
  }
  
  public var data : [[String : Any]] = []
  public var hitCount : Int
  /// The server stopped counting at `hitCount` (`"relation": "gte"`), so there are at least that many
  public var hitCountIsLowerBound : Bool
  public var fields : [SquashedFieldsArray]
  /// Each document in `data` flattened into its fields' values, in the same order.
  public var rows : [OrderedDictionary<String, Any>]
  /// Where each document in `data` lives, in the same order. nil for a hit without an `_index` or `_id`.
  public var refs : [DocumentRef?]
  public var error : String?
  public var errorTitle : String?

  /// A short label for a search's matching document count: "1 hit", "60 hits", or "10,000+ hits"
  /// when the server only counted up to a limit.
  public static func hitCountLabel(_ count: Int, isLowerBound: Bool = false) -> String {
    let number = count.formatted() + (isLowerBound ? "+" : "")
    return count == 1 && !isLowerBound ? "1 hit" : "\(number) hits"
  }
}
