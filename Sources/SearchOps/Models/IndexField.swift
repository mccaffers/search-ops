// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public struct IndexField : Hashable, Identifiable {
    public var id: UUID = UUID()
    public var name: String = ""
    public var type: String = ""
}

// TODO
// Switch to this from string, incase there
// are two indexes with the same name (?)
// not sure if thats possible
public struct IndexKey : Hashable, Identifiable {
    public var id: UUID = UUID()
    public var name: String = ""
}
