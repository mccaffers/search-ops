//
//  Sheet.swift
//  PocketSearch
//
//  Created by Ryan on 04/02/2023.
//

import Foundation

public enum SearchSheet: String, Identifiable {
    case query, main, fields 
    public var id: String { rawValue }
}
