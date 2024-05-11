// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
@available(iOS 15.0, *)

public class FilterObject: ObservableObject {
  
  public init(id: UUID = UUID(),
              query: QueryObject? = nil,
              dateField: SquashedFieldsArray? = nil,
              relativeRange: RelativeRangeFilter? = nil,
              absoluteRange: AbsoluteDateRangeObject? = nil,
              sort: SortObject? = nil) {
    self.query = query
    self.dateField = dateField
    self.relativeRange = relativeRange
    self.absoluteRange = absoluteRange
    self.sort = sort
  }
  
  @Published public var id: UUID = UUID()
  @Published public var query: QueryObject? = nil {
    didSet {
      id = UUID()
    }
  }
  @Published public var dateField: SquashedFieldsArray? = nil  {
    didSet {
      id = UUID()
    }
  }
  
  @Published public var sort: SortObject? = nil  {
    didSet {
      id = UUID()
    }
  }
  
  @Published public var relativeRange: RelativeRangeFilter? = nil
  {
    didSet {
      id = UUID()
    }
  }
  @Published public var absoluteRange: AbsoluteDateRangeObject? = nil
  {
    didSet {
      id = UUID()
    }
  }
  
}
