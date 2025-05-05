// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SettingsDetailEmptyView: View {
  
  var title : String
  
  var body: some View {
    VStack {
      HStack {
        Text(title)
          .foregroundColor(Color("TextColor"))
        
        Spacer()
        
        
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 15)
    }
    .padding(.vertical, 22)
    .background(Color("BackgroundAlt"))
    
    HStack (spacing:15) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 18))
        .foregroundColor(.orange)
      SettingDetailJsonViewer(text:"Unable to render mapping response as the response object is too large")
    }
    .padding(.horizontal, 20)
    .padding(.top, 10)
    .padding(.bottom, 30)
  }
}
