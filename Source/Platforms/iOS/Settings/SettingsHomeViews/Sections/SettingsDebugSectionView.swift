// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct SettingsDebugSectionView: View {
  
  @State var showTechnicalSettings = false
  
    var body: some View {
      VStack(spacing:5){
        Text("Debug Section")
          .foregroundColor(Color("TextSecondary"))
          .font(.system(size:15))
          .frame(maxWidth: .infinity, alignment:.leading)
        
        Button(action: {
          showTechnicalSettings=true
        }, label: {
          Text("Database Settings")
            .foregroundColor(.white)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color("Button"))
            .cornerRadius(5.0)

        })
      }
      .navigationDestination(isPresented: $showTechnicalSettings, destination: {
        TechnicalSettings()
      })

    }
}

#Preview {
    SettingsDebugSectionView()
}
#endif
