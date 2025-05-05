// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
