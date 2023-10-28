// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class HostDetailsWrap: ObservableObject {
    
    public init(item: HostDetails? = nil) {
        self.item = item
    }

    @Published public var item: HostDetails? = nil
}

