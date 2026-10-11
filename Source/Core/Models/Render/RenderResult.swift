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
@available(iOS 15.0, *)

public class RenderResult : ObservableObject {
  
  public init() {
    
  }
  public var results : [[String : Any]] = []
  public var error : ResponseError?
  public var pages : Int = 0
  public var hits : Int = 0
  /// The server stopped counting at `hits`, so there are at least that many
  public var hitsIsLowerBound : Bool = false
  public var fields : [SquashedFieldsArray]? = nil
  /// Each document in `results` flattened into its fields' values, in the same order.
  public var rows : [OrderedDictionary<String, Any>] = []
  /// Where each document in `results` lives, in the same order
  public var refs : [DocumentRef?] = []
  public var mapping : [SquashedFieldsArray]? = nil
  /// Round-trip time of the search request, set whether or not the request succeeded.
  public var duration : Duration? = nil
  /// Document counts over the time period, only asked for on the first page
  public var histogram : SearchHistogram? = nil
}
