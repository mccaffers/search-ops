// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 13.0, *)
@available(iOS 13.0, *)
class QueryObj: ObservableObject {
    @Published var queryString: String = "*"
    
    func Clear() {
        self.queryString = "*"
    }
}
