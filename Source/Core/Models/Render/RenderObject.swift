// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import OrderedCollections

@available(macOS 10.15, *)
@available(iOS 15.0, *)
public struct RenderObject {
  /// New for each set of results, so views can tell a new search from a redraw of the same results.
  public let id = UUID()
  public var headers : [SquashedFieldsArray]
  public var results : [OrderedDictionary<String, Any>]
  public var flat : [OrderedDictionary<String, Any>]? = nil
  public var dateField : SquashedFieldsArray? = nil
  /// Where each document in `results` lives, in the same order. Empty when not known.
  public var refs : [DocumentRef?] = []
}
