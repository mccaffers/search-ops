// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct AddHostConnectionView: View {
  
  @Binding var item: HostDetails
  @Binding var currentField: String
  @FocusState var focusedField: String?
  
  @State var schemaUpdate : HostScheme = HostScheme.HTTPS
  
  @State var refresh = UUID()
  
  var body: some View {
    
    Group {
      if let binding = Binding<HostURL>($item.host) {
        
        VStack(spacing:10) {
          AddHostConnectionSchemeView(localScheme: $schemaUpdate)
            .onChange(of: schemaUpdate) { newValue in
              HostsDataManager.setScheme(item: item, scheme: newValue)
              refresh = UUID()
            }
          
          AddConnectionLabel(identifer: "Host URL",
                             value: binding.url,
                             currentField: $currentField,
                             focusedField: _focusedField,
                             placeholder: "Host URL (eg. myhost.com)",
                             schemaUpdate: $schemaUpdate)
          
          AddConnectionLabel(identifer: "Port",
                             value: binding.port,
                             currentField: $currentField,
                             focusedField: _focusedField,
                             placeholder: "Port (eg. 9200)",
                             optionalTag: true,
                             schemaUpdate: .constant(.HTTPS))
          
          AddHostSelfSignedSSLView(value: binding.selfSignedCertificate)
        }
      }
    }.id(refresh)
    
  }
}
