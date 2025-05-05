// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(iOS 15, *)
public class LogHostDetails : Object  {
    @Persisted public var name: String = ""
    @Persisted public var host: HostURL? = HostURL()
    @Persisted public var env: String = ""
}
