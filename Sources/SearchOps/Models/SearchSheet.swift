// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public enum SearchSheet: String, Identifiable {
    case query, main, fields 
    public var id: String { rawValue }
}
