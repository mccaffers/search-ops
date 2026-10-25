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
  case saved
  case dashboards
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

private class WindowConfiguringNSView: NSView {
  var minFullScreenContentSize: NSSize = NSSize(width: 400, height: 300)

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if let window = self.window {
      window.minFullScreenContentSize = minFullScreenContentSize
    }
  }
}

struct WindowConfigurator: NSViewRepresentable {
  var minFullScreenContentSize: NSSize = NSSize(width: 400, height: 300)

  func makeNSView(context: Context) -> NSView {
    let view = WindowConfiguringNSView()
    view.minFullScreenContentSize = minFullScreenContentSize
    DispatchQueue.main.async {
      if let window = view.window {
        window.minFullScreenContentSize = minFullScreenContentSize
      }
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    if let configView = nsView as? WindowConfiguringNSView {
      configView.minFullScreenContentSize = minFullScreenContentSize
    }
    DispatchQueue.main.async {
      if let window = nsView.window {
        window.minFullScreenContentSize = minFullScreenContentSize
      }
    }
  }
}

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
  /// The dashboard open in the Dashboards tab, nil for the list
  @State var openDashboardId: UUID? = nil
  
  @StateObject var hostsUpdated = HostUpdatedNotifier()
  @StateObject var searchHistoryManager = SearchHistoryDataManager()
  @StateObject var serverObjects = HostsDataManager()
  @StateObject var searchHandoff = macosSearchHandoff()
  @StateObject var manageCoordinator = ManageNavigationCoordinator()
  
  @FocusState var focusedField: String?
  @State private var showingKeyUnavailable = false
  
  var body: some View {
    NavigationStack {
      
      CustomSplitView(
        menuPanel: {
          
          ZStack {
            macosMainMenu(sidebar: $sidebar,
                          fullScreen: $fullScreen,
                          backgroundColor:  Color("Background"),
                          serverObjects: serverObjects,
                          searchHistoryManager: searchHistoryManager)
            .disabled(selection != .None)
            
            if selection != .None {
              RoundedRectangle(cornerRadius: 5)
                .fill(Color.black.opacity(0.1))
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
                              fullScreen: $fullScreen,
                              sidebar: $sidebar,
                              serverObjects: serverObjects,
                              searchHistoryManager: searchHistoryManager,
                              searchHandoff: searchHandoff,
                              onBackToDashboard: { id in
                                openDashboardId = id
                                searchHandoff.clearDashboardReturn()
                                selection = .None
                                sidebar = .dashboards
                              })
              .opacity(sidebar == .hidden ? 1 : 0)
              .id(refreshMainView)
              .onChange(of: hostsUpdated.updated) { newValue in
                refreshMainView = UUID()
                print("refresh main view")
              }
            
            if sidebar == .settings {
              SettingsView(searchHistoryManager: searchHistoryManager,
                           fullScreen: $fullScreen)
                           
            } else if sidebar == .saved {
              macosSavedDocumentsView(fullScreen: $fullScreen,
                                      serverObjects: serverObjects,
                                      onSearch: { request in
                                        searchHandoff.send(request)
                                        selection = .None
                                        sidebar = .hidden
                                      })
            } else if sidebar == .dashboards {
              macosDashboardsView(fullScreen: $fullScreen,
                                  serverObjects: serverObjects,
                                  openDashboardId: $openDashboardId,
                                  onEdit: { search, dashboard in
                                    let dataView = search.dataViewId.flatMap { DataViewDataManager().view(id: $0) }
                                    searchHandoff.send(search.request(dataView: dataView),
                                                       returningTo: macosDashboardReturn(id: dashboard.id,
                                                                                         title: dashboard.title))
                                    selection = .None
                                    sidebar = .hidden
                                  })
            } else if sidebar == .hosts {
              macosHostsView(fullScreen:$fullScreen,
                             serverObjects: serverObjects, 
                             hostsUpdated: hostsUpdated, 
                             searchHistoryManager: searchHistoryManager,
                             coordinator: manageCoordinator,
                             selection: $selection)
            } else if sidebar == .develop {
              macosDevelopView(fullScreen: $fullScreen,
                               serverObjects: serverObjects,
                               hostsUpdated: hostsUpdated)
            }
          }
          .environmentObject(hostsUpdated)
          .environmentObject(manageCoordinator)
        })
      
      
    }
    .onReceive(fullScreenNotification, perform: { notification in
      fullScreen = true
      if let window = (notification as Notification).object as? NSWindow {
        window.minFullScreenContentSize = NSSize(width: 400, height: 300)
      }
    })
    .onReceive(fullScreenExitNotification, perform: { _ in
      fullScreen = false
    })
    // Hosts opens on its list each time; links from Search set the screen before switching here
    .onChange(of: sidebar) { newValue in
      if newValue != .hosts {
        manageCoordinator.reset()
      }
    }
    .background(Color("Background") )
    .background(WindowConfigurator(minFullScreenContentSize: NSSize(width: 400, height: 300)))
    .onAppear {
      // Safety net for data views and saved items left behind by a host deleted elsewhere
      let hostIds = Set(serverObjects.items.filter { !$0.isInvalidated }.map(\.id))
      DataViewDataManager().pruneOrphans(validHostIds: hostIds)
      SavedDocumentDataManager().pruneOrphans(validHostIds: hostIds)
      SavedSearchDataManager().pruneOrphans(validHostIds: hostIds)
      DashboardDataManager().pruneMissingSearches(validSearchIds: Set(SavedSearchDataManager().all().map(\.id)))
      // Recent searches saved before field filters kept everything in a nested filter object
      searchHistoryManager.migrateAwayFromFilterObjects()
      // The data managers above have opened the realm by now
      showingKeyUnavailable = RealmManager.keyUnavailable
    }
    .alert("Couldn't Load Your Data", isPresented: $showingKeyUnavailable) {
      Button("OK", role: .cancel) { }
      Button("Quit Search Ops") {
        NSApplication.shared.terminate(nil)
      }
    } message: {
      Text("Search Ops couldn't read its encryption key from the Keychain, so your hosts and saved searches aren't loaded. Nothing has been deleted.\n\nAnything you add now won't be saved. Quit Search Ops and open it again, and choose Allow if macOS asks to use the Keychain.")
    }
    
  }
}
#endif
