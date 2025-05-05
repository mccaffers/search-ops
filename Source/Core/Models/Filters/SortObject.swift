// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 10.15, *)
@available(iOS 15.0, *)
public class SortObject : ObservableObject {
  
  public init(order: SortOrderEnum, field: SquashedFieldsArray) {
    self.order = order
    self.field = field
  }
  
  @Published public var order: SortOrderEnum
  @Published public var field: SquashedFieldsArray
  
  public func ejectRealmObjet() -> RealmSortObject {
    let sortObj = RealmSortObject()
    sortObj.order = self.order
    sortObj.field = RealmSquashedFieldsArray(squasedField: self.field)
    return sortObj
  }
}

@available(macOS 10.15, *)
@available(iOS 15.0, *)
public class RealmSortObject : EmbeddedObject {
  
  @Persisted public var order: SortOrderEnum
  @Persisted public var field: RealmSquashedFieldsArray?
  
}
