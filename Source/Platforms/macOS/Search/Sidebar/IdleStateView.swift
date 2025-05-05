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
  var searchAction: () -> Void
  var hideAction:()->()
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {

        macosDropdownIndiciesButton(selectedIndex: $selectedIndex,
                                    sortedIndex: "_all",
                                    searchAction: searchAction,
                                    hideAction: hideAction)
        .padding(.horizontal, 5)
   
        
        let sortedIndex = indexArray.sorted(by: <)
        ForEach(sortedIndex.indices, id: \.self) { index in
         
          macosDropdownIndiciesButton(selectedIndex: $selectedIndex,
                                      sortedIndex: sortedIndex[index], 
                                      searchAction: searchAction,
                                      hideAction: hideAction)
          .padding(.horizontal, 5)
          
        }
      }
      .frame(maxWidth: .infinity)
    }
    
  }
}
