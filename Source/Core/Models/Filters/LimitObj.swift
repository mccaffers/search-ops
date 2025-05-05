// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public class LimitObj: ObservableObject {
    
    public init(size: Int = 25) {
        self.size = size
    }
    
    @Published public var size: Int = 25
}
