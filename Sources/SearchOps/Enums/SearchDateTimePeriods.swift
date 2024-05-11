// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public enum SearchDateTimePeriods: String, CaseIterable, PersistableEnum {
  case Seconds
  case Minutes
  case Hours
  case Days
  case Weeks
  case Months
  case Years
}
