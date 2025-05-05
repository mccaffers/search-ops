// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class SearchResult : ObservableObject {
  
  public init(data: [[String : Any]] = [], hitCount:Int = 0, fields : [SquashedFieldsArray] = [], error: String? = nil) {
    self.data = data
    self.error = error
    self.hitCount = hitCount
    self.fields = fields
  }
  
  public var data : [[String : Any]] = []
  public var hitCount : Int
  public var fields : [SquashedFieldsArray]
  public var error : String?
}
