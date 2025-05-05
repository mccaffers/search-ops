// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchNavigationHeaderView: View {
  
  @Binding var viewFavourites : Bool
  
  var body: some View {
    
    HStack {
      
      Text("Search")
        .font(.system(size: 40, weight: .semibold))
        .padding(.leading, 15)
      
      Spacer()
      
    }
  }
}
