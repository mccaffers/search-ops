// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosIndiceList: View {
  @Binding var selectedIndex: String
  var indexArray: [String]
  var showAll: Bool = true
  var searchAction: () -> Void
  var hideAction: () -> ()
  
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        if showAll {
          macosDropdownIndiciesButton(selectedIndex: $selectedIndex,
                                      sortedIndex: "_all",
                                      searchAction: searchAction,
                                      hideAction: hideAction)
          .padding(.horizontal, 5)
        }
        
        let sortedIndex = indexArray.sorted(by: <)
        ForEach(sortedIndex, id: \.self) { indexName in
          macosDropdownIndiciesButton(selectedIndex: $selectedIndex,
                                      sortedIndex: indexName, 
                                      searchAction: searchAction,
                                      hideAction: hideAction)
          .padding(.horizontal, 5)
        }
        
        if !showAll && indexArray.isEmpty {
          HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(Color("TextSecondary"))
            Text("No matching indices")
              .foregroundColor(Color("TextSecondary"))
              .font(.subheadline)
          }
          .frame(maxWidth: .infinity)
          .frame(height: 50)
        }
      }
      .frame(maxWidth: .infinity)
    }
  }
}
