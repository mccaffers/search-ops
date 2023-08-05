//
//  QuickButton.swift
//  PocketSearch
//
//  Created by Ryan on 04/02/2023.
//

import Foundation

public enum QuickButtons: String, CaseIterable, Hashable {
    case None
    case ThirtyMins = "Last 30 minutes"
    case LastHour = "Last 2 Hours"
    case LastDay = "Last Day"
    case LastWeek = "Last Week"
}
