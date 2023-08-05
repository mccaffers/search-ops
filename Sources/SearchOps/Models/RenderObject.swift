//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 29/06/2023.
//

import Foundation
import OrderedCollections

@available(iOS 15.0, *)
public struct RenderObject {
    public var headers : [SquasedFieldsArray]
    public var results : [OrderedDictionary<String, Any>]
}
