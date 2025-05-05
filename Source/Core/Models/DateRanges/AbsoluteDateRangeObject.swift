// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
@available(iOS 15.0, *)

public class AbsoluteDateRangeObject : ObservableObject {
  
  public init(from: Date = Date.now,
              to: Date = Date.now) {
    self.from = from
    self.to = to
  }
  
  
  @Published public var from: Date = Date.now
  @Published public var to: Date = Date.now
  @Published public var fromNow: Bool = false
  @Published public var toNow: Bool = false
  
  public func generatePrettyString() -> String {
    var myString = from.formatted()
    myString += " > "
    
    if toNow {
      myString += "Now"
    } else {
      myString += to.formatted()
    }
    return myString
  }
  
  public func ejectRealmObject() -> RealmAbsoluteDateRangeObject {
    let realmObj = RealmAbsoluteDateRangeObject()
    realmObj.from = self.from
    realmObj.to = self.to
    realmObj.toNow = self.toNow
    realmObj.fromNow = self.fromNow
    return realmObj
  }
  
}
