// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import OrderedCollections

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class SearchResult : ObservableObject {
  
  public init(data: [[String : Any]] = [], hitCount:Int = 0, fields : [SquashedFieldsArray] = [], rows: [OrderedDictionary<String, Any>] = [], error: String? = nil, errorTitle: String? = nil) {
    self.data = data
    self.rows = rows
    self.error = error
    self.hitCount = hitCount
    self.fields = fields
    self.errorTitle = errorTitle
  }
  
  public var data : [[String : Any]] = []
  public var hitCount : Int
  public var fields : [SquashedFieldsArray]
  /// Each document in `data` flattened into its fields' values, in the same order.
  public var rows : [OrderedDictionary<String, Any>]
  public var error : String?
  public var errorTitle : String?
}
