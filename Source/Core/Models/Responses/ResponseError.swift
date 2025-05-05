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

public class ResponseError : LocalizedError {
  public let title: String
  public let message: String
  public let type : ErrorResponseType
  
  public init(title : String, message: String, type: ErrorResponseType) {
    self.message = message
    self.title = title
    self.type = type
  }
  
  public func ejectRealm() -> RealmResponseError {
    let realmObj = RealmResponseError()
    realmObj.message = self.message
    realmObj.title = self.title
    realmObj.type = self.type
    return realmObj
  }
}

