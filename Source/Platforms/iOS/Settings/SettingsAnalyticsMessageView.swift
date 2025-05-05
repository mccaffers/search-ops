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
        
        
        Text("The entire application is written in Swift, with only one external framework (Realm) to provide a local on device database. Realm is an open source mobile database by MongoDB. Encryption is turned on by default.")
          .frame(maxWidth: .infinity, alignment:.leading)
        
        VStack (spacing:5){
          Button {
            openURL(URL(string: "https://github.com/realm/realm-swift")!)
          } label: {
            HStack {
              Image(systemName: "link")
              Text("realm / realm-swift")
            }
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(Color("Button"))
            .cornerRadius(5)
          }
          Text("Opens an external link to the Github Repository")
            .font(.system(size: 14))
            .foregroundColor(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment:.center)
        }
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
