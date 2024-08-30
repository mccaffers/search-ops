// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
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
    var sortObj = RealmSortObject()
    sortObj.order = self.order
    sortObj.field = RealmSquashedFieldsArray(squasedField: self.field)
    return sortObj
  }
}

public class RealmSortObject : EmbeddedObject {
  
  @Persisted public var order: SortOrderEnum
  @Persisted public var field: RealmSquashedFieldsArray?
  
}
