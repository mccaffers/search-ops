// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 13.0, *)
@available(iOS 15.0, *)

public class RenderResult : ObservableObject {
  
  public init() {
    
  }
  public var results : [[String : Any]] = []
  public var error : ResponseError?
  public var pages : Int = 0
  public var hits : Int = 0
  public var fields : [SquashedFieldsArray]? = nil
  public var mapping : [SquashedFieldsArray]? = nil
}
