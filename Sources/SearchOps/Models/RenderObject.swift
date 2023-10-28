// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import OrderedCollections

@available(macOS 10.15, *)
@available(iOS 15.0, *)
public struct RenderObject {
    public var headers : [SquasedFieldsArray]
    public var results : [OrderedDictionary<String, Any>]
}
