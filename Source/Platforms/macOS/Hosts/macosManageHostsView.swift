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
  case indexList
}

@MainActor public class ManageNavigationCoordinator: ObservableObject {
  @Published public var screen: ManageScreen = .hostList
  @Published public var selectedHost: HostDetails? = nil

  public init(screen: ManageScreen = .hostList, selectedHost: HostDetails? = nil) {
    self.screen = screen
    self.selectedHost = selectedHost
  }

  public func selectHost(_ host: HostDetails) {
    guard !host.isInvalidated else { return }
    selectedHost = host
    screen = .hostOptions
  }

  public func navigateToListIndexes() {
    screen = .indexList
  }

  public func goBack() {
    switch screen {
    case .indexList:
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
    screen = .hostList
  }

  public func validateCurrentHost(against hosts: [HostDetails]) {
    guard let currentHost = selectedHost else {
      if screen != .hostList {
        screen = .hostList
      }
      return
    }

    if currentHost.isInvalidated {
      selectedHost = nil
      screen = .hostList
      return
    }

    let currentId = currentHost.id
    if !hosts.contains(where: { !$0.isInvalidated && $0.id == currentId }) {
      selectedHost = nil
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

@MainActor
struct macosManageHostsView: View {
  @Binding var fullScreen: Bool
  @ObservedObject var serverObjects: HostsDataManager
  @ObservedObject var hostsUpdated: HostUpdatedNotifier

  @StateObject var coordinator = ManageNavigationCoordinator()

  var activeHosts: [HostDetails] {
    serverObjects.items.filter { !$0.isInvalidated }
  }

  init(fullScreen: Binding<Bool> = .constant(false),
       serverObjects: HostsDataManager,
       hostsUpdated: HostUpdatedNotifier) {
    self._fullScreen = fullScreen
    self.serverObjects = serverObjects
    self.hostsUpdated = hostsUpdated
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
            onListIndexes: { coordinator.navigateToListIndexes() }
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

  @ViewBuilder
  private var hostListView: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Manage Hosts")
          .font(.system(size: 22, weight: .light))
        Spacer()
      }
      .padding(.top, 10)
      .padding(.bottom, 5)

      if activeHosts.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "server.rack")
            .font(.system(size: 32))
            .foregroundColor(Color("TextSecondary"))
          Text("No Configured Hosts")
            .font(.headline)
          Text("Add a host in Host Management to begin managing it.")
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(activeHosts, id: \.id) { item in
              macosManageHostCardView(item: item) {
                coordinator.selectHost(item)
              }
            }
          }
        }
      }

      Spacer()
    }
  }
}

#Preview {
  macosManageHostsView(fullScreen: .constant(false),
                       serverObjects: HostsDataManager(),
                       hostsUpdated: HostUpdatedNotifier())
}
#endif
