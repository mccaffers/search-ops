// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

#if os(iOS)
extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)  // << here !!
    }
}
#endif

struct AddHostDescriptionDetails: View {
  
  @Binding var item: HostDetails
  @FocusState var focusedField: String?
  @Binding var currentField: String
  
  @State private var selection : ConnectionType = ConnectionType.CloudID
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 15
    ) {
      
      AddConnectionLabel(identifer: "Name",
                         value: $item.name,
                         currentField: $currentField,
                         focusedField: _focusedField,
                         placeholder: "Name (eg. My Host)",
                         schemaUpdate: .constant(.HTTPS))
      
      AddConnectionLabel(identifer: "Environment",
                         value: $item.env,
                         currentField: $currentField,
                         focusedField: _focusedField,
                         placeholder: "Environment (eg. Production)",
                         schemaUpdate: .constant(.HTTPS))
      
    }.padding(.horizontal, 20)
    
  }
}

