// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct SettingsSourceCodeModalView: View {
  @Environment(\.openURL) var openURL
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    VStack (spacing:0) {
      
      
      VStack(spacing:20) {
        Text("Search Ops app is Open Source, available on Github")
          .frame(maxWidth: .infinity, alignment:.leading)
        
        Text("This repository contains the full application, the SwiftUI and Business logic for processing and querying of your infrastructure. The build hash aligns with the commit hash on Github")
          .frame(maxWidth: .infinity, alignment:.leading)
        
        Text("Build: " + (Bundle.main.appHash ?? ""))
          .frame(maxWidth: .infinity, alignment:.leading)
        
        VStack (spacing:5){
          Button {
            openURL(URL(string: "https://github.com/mccaffers/search-ops")!)
          } label: {
            HStack {
              Image(systemName: "link")
              Text("mccaffers / search-ops")
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
        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.top, 10)
      
      
      Spacer()
      
    }.background(Color("Background"))
      .navigationTitle("Open Source")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
  }
}
#endif
