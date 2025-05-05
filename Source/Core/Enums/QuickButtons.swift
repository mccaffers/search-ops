// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
