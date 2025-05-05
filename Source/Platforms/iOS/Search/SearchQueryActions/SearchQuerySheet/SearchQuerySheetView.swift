// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchQuerySheetView: View {
  
  var body: some View {
    VStack (spacing:0)  {
      SearchQueryPrebuilt()
      
      Spacer()
      
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    
    .background(Color("Background"))
    .navigationTitle("Query Filter")
#if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
#endif
    
  }
}
