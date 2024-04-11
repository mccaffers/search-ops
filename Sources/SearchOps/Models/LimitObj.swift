// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
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
