// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)

struct iosSearchRecentView: View {
    
  @EnvironmentObject var orientation : Orientation
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject var serverObjects : HostsDataManager
  
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
  
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  
   
  var itemLimit = 0
  var body: some View {
    NavigationStack {
      
      
      VStack (spacing:0) {
        
        iosSearchHistoryList(searchManager: searchHistoryManager,
                             serverObjects:serverObjects,
                             request: { selectedHost, selectedIndex, filterObject in
          Task {
            dismiss()
            await request(selectedHost, selectedIndex, filterObject)
          }
        }, itemLimit: itemLimit)
        
      }
      .background(Color("Background"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
      .navigationTitle("Recent Searches")
      .toolbar {
        if orientation.isLandscape {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              dismiss()
            } label: {
              Text("Close")
                .foregroundColor(Color("TextColor"))
            }
            
          }
        }
      }
      .onAppear {
        searchHistoryManager.refresh()
      }
    }
    .onAppear {
      UINavigationBar.appearance() .backgroundColor = UIColor(Color("BackgroundAlt"))
    }
    .onDisappear {
      UINavigationBar.appearance().backgroundColor = UIColor(Color("Background"))
    }
    
  }
  
}
#endif
