// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public enum QuickButtons: String, CaseIterable, Hashable {
    case None
    case ThirtyMins = "Last 30 minutes"
    case LastHour = "Last 2 Hours"
    case LastDay = "Last Day"
    case LastWeek = "Last Week"
}
