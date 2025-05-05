// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosIndicesView: View {

  var selectedIndex: String
  @Binding var selection: macosSearchViewEnum
  
    var body: some View {
        VStack {
          Button {
            selection = .Indices
          } label: {
              HStack{
                VStack {
                  if selectedIndex.isEmpty {
                    Text("Select an index")
                  } else {
                    Text(selectedIndex)
                  }
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
              }
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 10)
              .background(Color("Button"))
              .clipShape(RoundedRectangle(cornerRadius: 5))
            
          }.buttonStyle(PlainButtonStyle())
            .padding(.leading, 10)
        }
        .frame(maxWidth: .infinity)
    }

}
