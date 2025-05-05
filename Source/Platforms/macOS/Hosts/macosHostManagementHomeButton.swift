// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosHostManagementHomeButton: View {
  
  @Binding var selectedHostToEdit : HostDetails?
  @Binding var selection: macosSearchViewEnum
  
  var item : HostDetails
  @State private var isHovered: Bool = false // State variable to track hover state
  var body: some View {
    if !item.isInvalidated {
      Button {
        selectedHostToEdit = item
        selection = .HostManagement
      } label: {
        VStack (alignment: .leading) {
          Text(item.name)
          Text(item.env)
            .font(.subheadline)
        }
        .padding(.vertical, 10)
        .padding(.leading, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? Color("ButtonHighlighted") : Color("Button") )
        .clipShape(.rect(cornerRadius: 5))
        .contentShape(Rectangle())
        
      }.buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isHovered = hovering // Update hover state
        }
    }
  }
}
