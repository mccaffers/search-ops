// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 10.15, *)
@available(iOS 15.0, *)
public class RenderedFields : ObservableObject {
    
    @Published
    public var fields: [SquashedFieldsArray]
    
    @Published
    public var id : UUID = UUID()
    
    public init(fields: [SquashedFieldsArray]) {
        self.fields = fields
    }
}
