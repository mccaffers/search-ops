// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public enum BuiltInQueries: String, PersistableEnum {
  case Indexes
  case IndexMappings
  case SearchIndex
  case CustomSearch
}
