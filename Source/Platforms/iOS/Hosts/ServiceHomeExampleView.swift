// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct ServiceHomeExampleView: View {
  var body: some View {
    
    VStack (alignment:.center, spacing:20){
      
      Text("No Saved Hosts")
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
      
    }
    .background(Color("BackgroundAlt"))
    .padding(.horizontal, 15)
    .cornerRadius(5)
    .padding(.top, 10)
    
  }
}

struct ServiceHomeExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceHomeExampleView()
    }
}
