// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct LoadingView: View {
  
  var hostName: String
  var selectedIndex: String
  
  var body: some View {
    VStack {
      VStack(spacing: 20) {
        ProgressView()
          .controlSize(.large)
        Text("Requesting fields")
        
        HStack {
          Text(hostName)
            .padding(10)
            .background(Color("InactiveButtonBackground"))
            .cornerRadius(5)
          Text("/")
          Text(selectedIndex)
            .padding(10)
            .background(Color("InactiveButtonBackground"))
            .cornerRadius(5)
          Text("/")
          Text("_mapping")
            .padding(10)
            .background(Color("InactiveButtonBackground"))
            .cornerRadius(5)
        }
        
        Rectangle()
          .fill(.clear)
          .frame(height: 200)
        
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("Background"))
  }
}
