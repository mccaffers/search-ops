//
//  IndexField.swift
//  PocketSearch
//
//  Created by Ryan on 04/02/2023.
//

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
