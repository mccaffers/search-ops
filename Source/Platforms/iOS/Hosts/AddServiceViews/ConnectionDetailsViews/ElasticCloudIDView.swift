// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct ElasticCloudIDView: View {
    
    @Binding var item: HostDetails
    @Binding var currentField: String
    @FocusState var focusedField: String?
    
    var body: some View {
      AddConnectionLabel( identifer : "Cloud ID",
                          value: $item.cloudid,
                          currentField: $currentField,
                          focusedField: _focusedField,
                          placeholder: "CloudID (from elastic.co)",
                          schemaUpdate: .constant(.HTTPS))
    }
}

