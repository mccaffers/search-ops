// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchMainHeaderView: View {
  @Binding var selectedHost: HostDetails?
  @Binding var selectedIndex: String
  var searchAction: () -> Void
  @State private var searchText = ""
  @Binding var selection: macosSearchViewEnum
  
  var body: some View {
    VStack (spacing:0){
      HStack {
        Button {
          selection = .Hosts
        } label: {
          Text(selectedHost?.name ?? "Select a host")
            .padding(10)
        }
        .buttonStyle(MyButtonStyle(color:Color("Button")))
        
        Button {
          selection = .Indices
          
        } label: {
          Text(selectedIndex.isEmpty ? "Select an index" : selectedIndex)
            .padding(10)
        }
        .buttonStyle(MyButtonStyle(color:Color("Button")))
        .disabled(selectedHost == nil || selectedIndex.isEmpty)
        
        Spacer()
      }
      
    
    }.padding(5)
      .frame(maxWidth: 200)
  
  }
}
