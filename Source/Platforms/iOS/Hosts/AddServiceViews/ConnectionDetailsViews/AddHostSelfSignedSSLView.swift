// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct AddHostSelfSignedSSLView: View {
  
  @Binding var value: Bool
  
  @State var refresh : UUID = UUID()
  
  var body: some View {
    
    VStack (spacing:0) {
            
      Toggle(isOn: $value) {
        Text("Self-Signed TLS/SSL Certificate")
          .font(.system(size: 15))
      }
      .id(refresh)
      .padding(.bottom, 5)
      .onAppear {
        refresh=UUID()
        print("toggle is : ", value.string)
      }
    }
  }
}
