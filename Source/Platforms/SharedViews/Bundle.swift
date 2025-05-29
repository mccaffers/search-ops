// SearchOps Source Code
// Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

extension Bundle {
    
  var appHash: String? {
        infoDictionary?["GitCommitHashApp"] as? String
    }
  
  static let myBundleID = "com.mccaffers.searchops.prod"
    
}
