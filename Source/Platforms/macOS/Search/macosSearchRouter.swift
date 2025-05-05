// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)

enum macosSearchRouterPath: Hashable {
  case WelcomeScreen
  case MainSearch
}

struct macosSearchRouter: View {
  
  @State var macosSearchRouterPath : macosSearchRouterPath = .WelcomeScreen
  @State var selectedHost: HostDetails?
  @State var selectedIndex: String = ""
  
  // ContentView needs to know to capture click events
  // and modify the background color for the title bar
  @Binding var selection: macosSearchViewEnum
  @Binding var showingTextFieldSuggestions : Bool
  @Binding var fullScreen : Bool
  @Binding var sidebar : sideBar
  
  @ObservedObject var serverObjects : HostsDataManager
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  
  @StateObject var filterObject : FilterObject = FilterObject()
  
  func request(selectedHost: HostDetails, selectedIndex: String, filterObject: FilterObject) {
    self.selectedHost = selectedHost
    self.selectedIndex = selectedIndex
    self.filterObject.dateField = filterObject.dateField
    self.filterObject.relativeRange = filterObject.relativeRange
    self.filterObject.absoluteRange = filterObject.absoluteRange
    self.filterObject.sort = filterObject.sort
    self.filterObject.query = filterObject.query
    macosSearchRouterPath = .MainSearch
  }
  
  var body: some View {
    if macosSearchRouterPath == .WelcomeScreen {
      macosSearchHomeViewCollection(selection:$selection, 
                                    fullScreen:$fullScreen,
                                    serverObjects: serverObjects,
                                    sidebar:$sidebar,
                                    request: request,
                                    searchHistoryManager: searchHistoryManager)
    } else if macosSearchRouterPath == .MainSearch {
      macosSearchMainView(macosSearchRouterPath:$macosSearchRouterPath,
                          serverObjects: serverObjects,
                          selectedHost:$selectedHost,
                          selectedIndex: $selectedIndex,
                          filterObject:filterObject, 
                          selection: $selection,
                          fullScreen: $fullScreen,
                          showingTextFieldSuggestions: $showingTextFieldSuggestions)
    }
  }
}
#endif
