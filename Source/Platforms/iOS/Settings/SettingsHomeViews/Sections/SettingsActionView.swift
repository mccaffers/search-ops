// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct SettingsActionView: View {
  
  @State private var showingSearchSettings = false
  
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  @ObservedObject var filterHistoryDataManager : FilterHistoryDataManager
  
  var body: some View {
    
    VStack(spacing:5){
      Button(action: {
        showingSearchSettings=true
      }, label: {
        Text("App Config & Limits")
          .foregroundColor(.white)
          .padding(.vertical, 15)
          .frame(maxWidth: .infinity, alignment: .center)
          .background(Color("Button"))
          .cornerRadius(5.0)
      })
    }
    .navigationDestination(isPresented: $showingSearchSettings, destination: {
      SearchSettingsView(searchHistoryManager: searchHistoryManager, 
                         filterHistoryDataManager: filterHistoryDataManager)
    })
    
  }
}
#endif

