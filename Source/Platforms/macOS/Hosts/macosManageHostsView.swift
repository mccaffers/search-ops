// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
public enum ManageScreen: Equatable {
  case hostList
  case hostOptions
  case clusterHealth
  case indexList
  case indexDetail
  case userList
  case dataViewList
  case dataViewEditor
}

@MainActor public class ManageNavigationCoordinator: ObservableObject {
  @Published public var screen: ManageScreen = .hostList
  @Published public var selectedHost: HostDetails? = nil
  @Published public var selectedIndex: String? = nil
  @Published public var selectedIndexStats: IndexStatsItem? = nil
  // nil on the editor means a new data view
  @Published public var selectedDataViewId: UUID? = nil

  public init(
    screen: ManageScreen = .hostList,
    selectedHost: HostDetails? = nil,
    selectedIndex: String? = nil,
    selectedIndexStats: IndexStatsItem? = nil
  ) {
    self.screen = screen
    self.selectedHost = selectedHost
    self.selectedIndex = selectedIndex
    self.selectedIndexStats = selectedIndexStats
  }

  public func selectHost(_ host: HostDetails) {
    guard !host.isInvalidated else { return }
    selectedHost = host
    screen = .hostOptions
  }

  public func navigateToClusterHealth() {
    screen = .clusterHealth
  }

  public func navigateToListIndexes() {
    screen = .indexList
  }

  public func navigateToListUsers() {
    screen = .userList
  }

  public func navigateToDataViews() {
    selectedDataViewId = nil
    screen = .dataViewList
  }

  public func editDataView(_ id: UUID?) {
    selectedDataViewId = id
    screen = .dataViewEditor
  }

  /// Straight to a blank data view editor for the host, as the search screen's + does.
  /// Back then goes to that host's data views.
  public func openNewDataView(for host: HostDetails) {
    guard !host.isInvalidated else { return }
    selectedHost = host
    selectedIndex = nil
    selectedIndexStats = nil
    editDataView(nil)
  }

  public func selectIndex(_ indexName: String, stats: IndexStatsItem? = nil) {
    selectedIndex = indexName
    selectedIndexStats = stats
    screen = .indexDetail
  }

  public func goBack() {
    switch screen {
    case .indexDetail:
      screen = .indexList
      selectedIndex = nil
      selectedIndexStats = nil
    case .dataViewEditor:
      screen = .dataViewList
      selectedDataViewId = nil
    case .clusterHealth, .indexList, .userList, .dataViewList:
      screen = .hostOptions
    case .hostOptions:
      screen = .hostList
      selectedHost = nil
    case .hostList:
      break
    }
  }

  public func reset() {
    selectedHost = nil
    selectedIndex = nil
    selectedIndexStats = nil
    selectedDataViewId = nil
    screen = .hostList
  }

  public func validateCurrentHost(against hosts: [HostDetails]) {
    guard let currentHost = selectedHost else {
      if screen != .hostList {
        screen = .hostList
        selectedIndex = nil
        selectedIndexStats = nil
        selectedDataViewId = nil
      }
      return
    }

    if currentHost.isInvalidated {
      selectedHost = nil
      selectedIndex = nil
      selectedIndexStats = nil
      selectedDataViewId = nil
      screen = .hostList
      return
    }

    let currentId = currentHost.id
    if !hosts.contains(where: { !$0.isInvalidated && $0.id == currentId }) {
      selectedHost = nil
      selectedIndex = nil
      selectedIndexStats = nil
      selectedDataViewId = nil
      screen = .hostList
    }
  }
}

struct macosManageHostCardView: View {
  var item: HostDetails
  var onSelect: () -> Void
  @State private var isHovered: Bool = false

  var body: some View {
    if !item.isInvalidated {
      Button(action: onSelect) {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
              .font(.system(size: 14, weight: .medium))
              .lineLimit(1)
            if !item.env.isEmpty {
              Text(item.env)
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .lineLimit(1)
            }
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color("TextSecondary"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? Color("ButtonHighlighted") : Color("Button"))
        .clipShape(.rect(cornerRadius: 5))
        .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .onHover { hovering in
        isHovered = hovering
      }
    }
  }
}

/// The Hosts tab's screens: the host list, then each host's options and the screens behind them.
/// The add and edit popup and deleting a host belong to `macosHostsView`, which wraps this.
@MainActor
struct macosManageHostsView: View {
  @Binding var fullScreen: Bool
  @ObservedObject var serverObjects: HostsDataManager
  @ObservedObject var hostsUpdated: HostUpdatedNotifier
  @ObservedObject var coordinator: ManageNavigationCoordinator
  var selection: macosSearchViewEnum = .None
  var onAddHost: () -> Void = {}
  var onEditHost: (HostDetails) -> Void = { _ in }
  var onDeleteHost: (HostDetails) -> Void = { _ in }

  var activeHosts: [HostDetails] {
    serverObjects.items.filter { !$0.isInvalidated }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      switch coordinator.screen {
      case .hostList:
        hostListView
      case .hostOptions:
        if let host = coordinator.selectedHost, !host.isInvalidated {
          macosManageHostOptionsView(
            host: host,
            onBack: { coordinator.goBack() },
            onEditHost: { onEditHost(host) },
            onDeleteHost: { onDeleteHost(host) },
            onClusterHealth: { coordinator.navigateToClusterHealth() },
            onListIndexes: { coordinator.navigateToListIndexes() },
            onListUsers: { coordinator.navigateToListUsers() },
            onDataViews: { coordinator.navigateToDataViews() }
          )
        } else {
          hostListView
            .onAppear {
              coordinator.reset()
            }
        }
      case .indexList:
        if let host = coordinator.selectedHost, !host.isInvalidated {
          macosManageIndexesView(
            host: host,
            onBack: { coordinator.goBack() },
            onSelectIndex: { indexName, stats in
              coordinator.selectIndex(indexName, stats: stats)
            }
          )
        } else {
          hostListView
            .onAppear {
              coordinator.reset()
            }
        }
      case .clusterHealth:
        if let host = coordinator.selectedHost, !host.isInvalidated {
          macosClusterHealthView(
            host: host,
            onBack: { coordinator.goBack() }
          )
        } else {
          hostListView
            .onAppear {
              coordinator.reset()
            }
        }
      case .userList:
        if let host = coordinator.selectedHost, !host.isInvalidated {
          macosManageUsersView(
            host: host,
            onBack: { coordinator.goBack() }
          )
        } else {
          hostListView
            .onAppear {
              coordinator.reset()
            }
        }
      case .dataViewList:
        if let host = coordinator.selectedHost, !host.isInvalidated {
          macosManageDataViewsView(
            host: host,
            onBack: { coordinator.goBack() },
            onCreate: { coordinator.editDataView(nil) },
            onEdit: { id in coordinator.editDataView(id) }
          )
        } else {
          hostListView
            .onAppear {
              coordinator.reset()
            }
        }
      case .dataViewEditor:
        if let host = coordinator.selectedHost, !host.isInvalidated {
          macosDataViewEditorView(
            host: host,
            dataViewId: coordinator.selectedDataViewId,
            onClose: { coordinator.goBack() }
          )
          // A fresh editor for each view, so no draft carries over
          .id(coordinator.selectedDataViewId)
        } else {
          hostListView
            .onAppear {
              coordinator.reset()
            }
        }
      case .indexDetail:
        if let host = coordinator.selectedHost, !host.isInvalidated, let indexName = coordinator.selectedIndex {
          macosManageIndexDetailView(
            host: host,
            indexName: indexName,
            initialStats: coordinator.selectedIndexStats,
            onBack: { coordinator.goBack() }
          )
        } else {
          hostListView
            .onAppear {
              coordinator.reset()
            }
        }
      }
    }
    .padding(.horizontal, 10)
    .background(Color("BackgroundFixedShadow"))
    .clipShape(.rect(cornerRadius: 5))
    .padding(.leading, 3)
    .padding(.trailing, 5)
    .padding(.bottom, 5)
    .padding(.top, fullScreen ? 5 : 0)
    .onAppear {
      serverObjects.refresh()
      coordinator.validateCurrentHost(against: serverObjects.items)
    }
    .onChange(of: hostsUpdated.updated) { _ in
      serverObjects.refresh()
      coordinator.validateCurrentHost(against: serverObjects.items)
    }
  }

  private var hostListView: some View {
    macosHostsListView(hosts: activeHosts,
                       selection: selection,
                       onAdd: onAddHost,
                       onSelect: { host in coordinator.selectHost(host) })
  }
}

#Preview {
  macosManageHostsView(fullScreen: .constant(false),
                       serverObjects: HostsDataManager(),
                       hostsUpdated: HostUpdatedNotifier(),
                       coordinator: ManageNavigationCoordinator())
}
#endif
