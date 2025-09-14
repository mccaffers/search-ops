// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosHostsSchemePickerView: View {

  @Binding var localScheme: HostScheme
  var body: some View {
    VStack (spacing:5) {
      Text("URI Scheme")
        .font(.system(size:12))
        .foregroundStyle(Color("TextSecondary"))
        .frame(maxWidth: .infinity, alignment: .leading)
      
      HStack {
        Button {
          localScheme = HostScheme.HTTPS
        } label: {
          Text("https")
            .padding(10)
            .background(localScheme == .HTTPS ? Color("ButtonHighlighted") : Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        
        
        Button {
          localScheme = HostScheme.HTTP
        } label: {
          Text("http")
            .padding(10)
            .background(localScheme == .HTTP ? Color("ButtonHighlighted") : Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        Spacer()
      }
    }
  }
}

