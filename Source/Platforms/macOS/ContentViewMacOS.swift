// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

import Combine

public enum sideBar {
  case hosts
  case settings
  case hidden
  case develop
}

enum macosSearchViewEnum: Hashable {
  case None
  case Hosts
  case HostManagement
  case Indices
  case DateTypePicker
  case DatePeriod
  case SearchScreenRefreshFrequency
  case SearchDocumentView
  case NewSearchDatePickerFrom
  case NewSearchDatePickerTo
  case NewSearchFieldPicker
  case NewSearchRelativeCustomValues
}

#if os(macOS)

class FullScreenObserver: ObservableObject {
  @Published var isFullScreen: Bool = false
  
  private var cancellable: AnyCancellable?
  
  init() {
    // Step 2: Subscribe to the notification
    cancellable = NotificationCenter.default.publisher(for: NSWindow.willEnterFullScreenNotification)
      .sink { [weak self] _ in
        self?.isFullScreen = true
      }
    
    // Optional: Also subscribe to the exit full screen notification
    cancellable = NotificationCenter.default.publisher(for: NSWindow.willExitFullScreenNotification)
      .sink { [weak self] _ in
        self?.isFullScreen = false
      }
  }
}

struct ContentViewMacOS: View {
  
  let fullScreenNotification = NotificationCenter.default.publisher(for: NSWindow.willEnterFullScreenNotification)
    .makeConnectable()
    .autoconnect()
  
  let fullScreenExitNotification = NotificationCenter.default.publisher(for: NSWindow.willExitFullScreenNotification)
    .makeConnectable()
    .autoconnect()
  
  @State var sidebar : sideBar = .hidden
  @State var fullScreen = false
  @State var selection: macosSearchViewEnum = .None
  
  @State var refreshMainView = UUID()
  @State var showingTextFieldSuggestions = false
  
  @StateObject var hostsUpdated = HostUpdatedNotifier()
  @StateObject var searchHistoryManager = SearchHistoryDataManager()
  @StateObject var serverObjects = HostsDataManager()
  
  @FocusState var focusedField: String?
  
  var body: some View {
    NavigationStack {
      
      CustomSplitView(
        menuPanel: {
          
          ZStack {
            macosMainMenu(sidebar: $sidebar,
                          fullScreen: $fullScreen,
                          backgroundColor: selection != .None ? Color("BackgroundFixedShadow") : Color("Background"),
                          serverObjects: serverObjects,
                          searchHistoryManager: searchHistoryManager)
            .disabled(selection != .None)
            
            if selection != .None {
              Rectangle().fill(Color.clear)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                  selection = .None
                }
            }
          }
          
        },
        rightPanel: {
          ZStack {
            
            macosSearchRouter(selection:$selection, 
                              showingTextFieldSuggestions: $showingTextFieldSuggestions,
                              fullScreen: $fullScreen,
                              sidebar: $sidebar,
                              serverObjects: serverObjects,
                              searchHistoryManager: searchHistoryManager)
              .opacity(sidebar == .hidden ? 1 : 0)
              .simultaneousGesture(TapGesture().onEnded({
                if showingTextFieldSuggestions {
                  showingTextFieldSuggestions = false
                }
              }))
              .id(refreshMainView)
              .onChange(of: hostsUpdated.updated) { newValue in
                refreshMainView = UUID()
                print("refresh main view")
              }
            
            if sidebar == .settings {
              SettingsView(searchHistoryManager: searchHistoryManager,
                           fullScreen: $fullScreen)
                           
            } else if sidebar == .hosts {
              macosHostsView(fullScreen:$fullScreen,
                             serverObjects: serverObjects, 
                             hostsUpdated: hostsUpdated, 
                             searchHistoryManager: searchHistoryManager,
                             selection: $selection)
            } else if sidebar == .develop {
              macosDevelopView(fullScreen: $fullScreen)
            }
          }
          .environmentObject(hostsUpdated)
        })
      
      
    }
    .onReceive(fullScreenNotification, perform: { _ in
      fullScreen = true
    })
    .onReceive(fullScreenExitNotification, perform: { _ in
      fullScreen = false
    })
    .background(selection == .None ? Color("Background") : Color("BackgroundFixedShadow"))
    
  }
}
#endif
