// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct Navigation: View {
  
  @StateObject var serverObjects: HostsDataManager = HostsDataManager()
  @StateObject var settingsManager: SettingsDataManager = SettingsDataManager()
  @StateObject var searchHistoryManager : SearchHistoryDataManager = SearchHistoryDataManager()
  @StateObject var filterHistoryDataManager = FilterHistoryDataManager()
  
  @State var hasShownInitialScreen = false
  
  @AppStorage("hasRemovedDuplicateFilters") private var hasRemovedDuplicateFilters: Bool = false
  
  var body: some View {
    
    TabView() {
      SearchNavigationStack(searchHistoryManager: searchHistoryManager,
                            filterHistoryDataManager: filterHistoryDataManager,
                            hasShownInitialScreen: $hasShownInitialScreen)
      .tabItem {
        Image(systemName: "magnifyingglass")
        Text("Search")
      }.tag(1)
      
      HostsNavigationStackView()
        .tabItem {
          Image(systemName: "server.rack")
          Text("Hosts")
        }.tag(2)
      
      SettingsHome(searchHistoryManager: searchHistoryManager, 
                   filterHistoryDataManager: filterHistoryDataManager)
        .tabItem {
          Image(systemName: "gearshape.2.fill")
          Text("Settings")
        }.tag(3)
      
    }
    .accentColor(Color("AccentColor"))
    .onAppear() {
      UITabBar.appearance().backgroundColor = UIColor(Color("TabBarColor"))
      UITabBar.appearance().barTintColor = UIColor(Color("TabBarColor"))
      
      UITabBar.appearance().clipsToBounds = true
      UITabBar.appearance().shadowImage = nil
      
      
      // Check to remove duplicates
      if !hasRemovedDuplicateFilters {
        print("Checking to remove duplicates and migrate away from filterobjects")
        filterHistoryDataManager.removeQueryDuplicates()
        searchHistoryManager.migrateAwayFromFilterObjects()
        hasRemovedDuplicateFilters = true
      } else {
        print("Duplicates/Filters already removed")
      }
      
    }
    .environmentObject(settingsManager)
    .environmentObject(serverObjects)
  }
}
#endif
