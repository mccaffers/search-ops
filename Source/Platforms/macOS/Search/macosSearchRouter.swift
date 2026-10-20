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
  // The data view the search was started from; selectedIndex is then its pattern
  @State var selectedDataView: DataView? = nil
  
  // ContentView needs to know to capture click events
  // and modify the background color for the title bar
  @Binding var selection: macosSearchViewEnum
  @Binding var fullScreen : Bool
  @Binding var sidebar : sideBar
  
  @ObservedObject var serverObjects : HostsDataManager
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  /// Searches sent from the Saved and Dashboards tabs
  @ObservedObject var searchHandoff : macosSearchHandoff
  /// Opens the dashboard a search was opened from with Edit
  var onBackToDashboard: (UUID) -> Void = { _ in }
  
  @StateObject var filterObject : FilterObject = FilterObject()
  /// Replaced to start a fresh search screen, which searches as it appears
  @State private var searchViewId = UUID()
  /// Columns from a saved search, until the search screen has shown them
  @State private var pendingSelectedFields: [String]? = nil
  @State private var pendingColumnWidths: [String: Double]? = nil
  /// The saved search being shown, kept here so it outlives a rebuilt search screen
  @State private var savedSearchLink: SavedSearchLink? = nil
  
  func request(selectedHost: HostDetails, selectedIndex: String, filterObject: FilterObject, dataView: DataView?) {
    self.selectedHost = selectedHost
    self.selectedIndex = selectedIndex
    self.selectedDataView = DataViewSelection.keep(dataView, forIndex: selectedIndex)
    self.filterObject.dateField = filterObject.dateField
    self.filterObject.relativeRange = filterObject.relativeRange
    self.filterObject.absoluteRange = filterObject.absoluteRange
    self.filterObject.sort = filterObject.sort
    self.filterObject.query = filterObject.query
    // A new search from the home screen has none, so this clears the last search's chips too
    self.filterObject.fieldFilters = filterObject.fieldFilters
    macosSearchRouterPath = .MainSearch
  }
  
  func refreshSavedSearchLink() {
    guard let link = savedSearchLink else { return }
    if let saved = SavedSearchDataManager().search(id: link.id) {
      savedSearchLink?.title = saved.displayTitle
    } else {
      savedSearchLink = nil
    }
  }

  /// Runs the search sent from the Saved tab, if there is one
  func runHandoff() {
    guard let pending = searchHandoff.take(),
          let host = serverObjects.getHostByID(pending.hostId),
          !host.isInvalidated else { return }
    let wasSearching = macosSearchRouterPath == .MainSearch
    selection = .None
    pendingSelectedFields = pending.selectedFields
    pendingColumnWidths = pending.columnWidths
    // A search from a saved document's value isn't a saved search
    savedSearchLink = pending.savedSearch.map {
      SavedSearchLink(id: $0.id, title: $0.displayTitle, baseline: SavedSearchState(request: pending))
    }
    request(selectedHost: host, selectedIndex: pending.index, filterObject: pending.filterObject, dataView: pending.dataView)
    // An open search screen only searches as it appears
    if wasSearching {
      searchViewId = UUID()
    }
  }
  
  var body: some View {
    Group {
      routes
    }
    .onChange(of: searchHandoff.pendingId) { _ in
      runHandoff()
    }
    .onAppear {
      // Sent while this screen was being rebuilt, eg. after a host change
      runHandoff()
    }
    .onChange(of: macosSearchRouterPath) { newValue in
      // Going home starts a new search, which isn't the saved one
      if newValue == .WelcomeScreen {
        savedSearchLink = nil
        searchHandoff.clearDashboardReturn()
      }
    }
    .onChange(of: sidebar) { newValue in
      // Back from another tab, where the saved search may have been renamed or removed
      if newValue == .hidden {
        refreshSavedSearchLink()
      }
    }
  }
  
  @ViewBuilder
  private var routes: some View {
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
                          selectedDataView: $selectedDataView,
                          pendingSelectedFields: $pendingSelectedFields,
                          pendingColumnWidths: $pendingColumnWidths,
                          savedSearchLink: $savedSearchLink,
                          dashboardReturn: searchHandoff.dashboardReturn,
                          onBackToDashboard: {
                            if let id = searchHandoff.dashboardReturn?.id {
                              onBackToDashboard(id)
                            }
                          },
                          filterObject:filterObject, 
                          selection: $selection,
                          fullScreen: $fullScreen)
      .id(searchViewId)
    }
  }
}
#endif
