// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct AboutSearchOpsView: View {
  
  @State var showingModal = false
  @State var showingAboutPage = false

  var body: some View {
    VStack(spacing:5){
      
      VStack(alignment:.leading, spacing:10) {
        
        HStack(spacing:5) {
          Text("Build: " + (Bundle.main.appHash ?? ""))
          Button {
            showingModal=true
          } label: {
            Image(systemName: "info.square.fill")
              .font(.system(size:20))
            .foregroundColor(Color("ButtonLight"))
            .padding(5)
            
          }
          .padding(.leading, -5)
          .padding(.top, -5)
          .padding(.bottom, -5)
        
        }
        .frame(maxWidth: .infinity, alignment:.leading)
        
        let databaseSize =  RealmManager.checkRealmFileSize()
        Text("Database Size: " +  String(format: "%.2f", databaseSize) + "mb")
          .frame(maxWidth: .infinity, alignment:.leading)
        
      }
      .font(.system(size: 14))
      .foregroundColor(Color("TextSecondary"))
      .padding(15)
      .background(Color("BackgroundAlt"))
      .cornerRadius(5)
      
    }
      .navigationDestination(isPresented:$showingModal, destination: {
        SettingsSourceCodeModalView()
      })
  
  }
}

#Preview {
    AboutSearchOpsView()
}
#endif
