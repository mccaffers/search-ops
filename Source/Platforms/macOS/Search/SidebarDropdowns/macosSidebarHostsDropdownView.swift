// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSidebarHostsDropdownView: View {
  
  var items : [HostDetails]
  @Binding var selectedHost: HostDetails?
  @Binding var selection: macosSearchViewEnum
  @Binding var fullScreen : Bool
  
  var validItems: [HostDetails] {
    items.filter { !$0.isInvalidated }
  }
  
  var totalListHeight: CGFloat {
    if validItems.isEmpty {
      return 60
    }
    return CGFloat(validItems.count * 40)
  }
  
  var maxPopupHeight: CGFloat {
    #if os(macOS)
    return (NSScreen.main?.visibleFrame.height ?? 800) * 0.5
    #else
    return 400
    #endif
  }
  
  var maxListHeight: CGFloat {
    max(80, maxPopupHeight - 60)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Hosts")
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.title2)
        .bold()
        .padding(.leading, 10)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color("Background"))
      
      if validItems.isEmpty {
        Text("No hosts available")
          .foregroundColor(Color("TextSecondary"))
          .font(.subheadline)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
      } else {
        ScrollView {
          VStack(spacing: 0) {
            ForEach(validItems, id: \.id) { item in
              HStack {
                macosSideBarHostsButton(selectedHost: $selectedHost,
                                        selection: $selection,
                                        item: item)
              }
              .padding(.horizontal, 5)
              .padding(.bottom, 5)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: min(totalListHeight, maxListHeight))
        .padding(.vertical, 5)
      }
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .background(Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    .padding(.leading, 10)
    .padding(.top, 5)
    #if os(macOS)
    .onExitCommand {
      selection = .None
    }
    #endif
  }
}

