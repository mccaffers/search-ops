// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct SettingsAnalyticsMessageView: View {
  
  @Environment(\.openURL) var openURL
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var orientation : Orientation
  
  var body: some View {
    VStack (spacing:0) {
      
      VStack(spacing:20) {
        Text("Privacy and trust is important! There are no analytics or tracking in Search Ops.")
          .frame(maxWidth: .infinity, alignment:.leading)
        
        
        Text("The entire application is written in Swift, with only one external framework (Realm) to provide a local on device database. Realm is an open source mobile database by MongoDB")
          .frame(maxWidth: .infinity, alignment:.leading)
        
        Text("Encryption is turned on by default")
          .frame(maxWidth: .infinity, alignment:.leading)
        
      }
      .padding(.horizontal, 20)
      .padding(.top, 10)
      
      
      Spacer()
      
    }.background(Color("Background"))
      .navigationTitle("No Analytics!")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
  }
}

#endif
