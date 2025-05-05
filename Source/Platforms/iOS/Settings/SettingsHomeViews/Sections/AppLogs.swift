// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct AppLogs: View {
  @State var showingApplicationLogs = false
 
  @State var showingAppLogs = false
  var body: some View {
    VStack(spacing:5){

      Button(action: {
        showingAppLogs=true
      }, label: {
        Text("Request Logs")
          .foregroundColor(.white)
          .padding(.vertical, 15)
          .frame(maxWidth: .infinity, alignment: .center)
          .background(Color("Button"))
          .cornerRadius(5.0)
        
      })
      
      Button(action: {
        showingApplicationLogs=true
      }, label: {
        Text("Application Logs")
          .foregroundColor(.white)
          .padding(.vertical, 15)
          .frame(maxWidth: .infinity, alignment: .center)
          .background(Color("Button"))
          .cornerRadius(5.0)
        
      })
   
    }
    .navigationDestination(isPresented: $showingApplicationLogs, destination: {
      SettingsApplicationLogsView()
    })

    .navigationDestination(isPresented:$showingAppLogs, destination: {
      SettingAppLogs()
    })
  }
}

#Preview {
    AppLogs()
}

#endif
