// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class SearchResult : ObservableObject {
    
    public init(data: [[String : Any]] = [], error: String? = nil) {
        self.data = data
        self.error = error
    }
    
    public var data : [[String : Any]] = []
    public var error : String?
}
