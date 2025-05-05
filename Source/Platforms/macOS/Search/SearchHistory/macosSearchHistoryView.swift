// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHistoryView: View {
  
  @ObservedObject var serverObjects: HostsDataManager
  
  @Binding var showing : macosSearchWelcomeScreenMainView
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  
  var active : Bool {
    return showing == .All || showing == .Recent
  }
    var body: some View {
      
      VStack(spacing:0){
        ZStack {
          HStack {
            Text("Recent Searches")
              .font(.system(size: 22, weight:.light))
              .padding(.bottom, active ? 8 : 0)
            
            Spacer()
            
            if searchHistoryManager.items.count == 0 {
              Text("No log entries")
                .padding(.trailing, 5)
            }
            
          }
          
          if !active {
            HStack {
              Spacer()
              Text("Tap to show").italic()
              Spacer()
            }
          }
        }
       
        if active {
          
          macosAppHistory(searchManager: searchHistoryManager,
                          serverObjects:serverObjects,
                          request: request)
        }
        
      }.frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
          if !active {
            withAnimation {
              showing = .All
            }
          }
          
        }
      
    }
}
