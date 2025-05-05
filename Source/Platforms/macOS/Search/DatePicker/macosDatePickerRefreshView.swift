// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosDatePickerRefreshView: View {
  
  @State var refreshText = ""
  
    var body: some View {
      VStack {
        
        Divider()
        
        HStack {
          
          Text("Refresh every")
          
          TextField("", text: $refreshText)
          
          Button {
            
          } label: {
            HStack {
              Text("Minutes")
              Image(systemName: "chevron.up.chevron.down")
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
              .background(Color("BackgroundAlt"))
              .cornerRadius(5)
          }
          .buttonStyle(PlainButtonStyle())
          
        }
        .padding(10)
        .background(Color("Button"))
        .cornerRadius(5)
      }
      .padding(.horizontal, 10)
      .background(Color("Background"))
      .padding(.bottom, 10)
    }
}

#Preview {
    macosDatePickerRefreshView()
}
