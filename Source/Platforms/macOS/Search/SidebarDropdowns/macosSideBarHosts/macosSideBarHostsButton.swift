// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSideBarHostsButton: View {
  
  @Binding var selectedHost: HostDetails?
  @Binding var selection: macosSearchViewEnum
  
  var item : HostDetails
  
  @State private var isHovered: Bool = false // State variable to track hover state
    
  var body: some View {
    Button {
      selectedHost = item
      selection = .Indices
    } label: {
      Text(item.name)
        .frame(maxWidth: .infinity,  alignment:.leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 5)
        .background(isHovered ? Color("BackgroundAlt").opacity(0.3) : Color.clear)
        .clipShape(.rect(cornerRadius: 5))
        .contentShape(Rectangle())
        
    }.buttonStyle(PlainButtonStyle())
      .onHover { hovering in
        isHovered = hovering // Update hover state
      }
  }
}
