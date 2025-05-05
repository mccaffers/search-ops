// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchRangeSheetView: View {
  
  @State var range: String = ""
  @Binding var presentedSheet: SearchSheet?
  
  var body: some View {
    VStack (spacing:0)  {
      VStack (spacing:0) {
        SearchRangeSheetHeader()
      }
      
      .background(Color("Button"))
      
      
      Text("Results to show:")
      TextField("Value", text: $range)
      Button {
        //
      } label: {
        Text("Save")
      }
      
      Spacer()
      
      
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("Background"))
  }
}

