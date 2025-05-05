// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
