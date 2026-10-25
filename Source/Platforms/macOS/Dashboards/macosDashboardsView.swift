// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

/// The Dashboards tab: the list of dashboards, or the one that's open
struct macosDashboardsView: View {
  @Binding var fullScreen: Bool
  @ObservedObject var serverObjects: HostsDataManager
  /// The dashboard shown, nil for the list. Kept by the window, so the tab reopens on it.
  @Binding var openDashboardId: UUID?
  /// Opens a panel's saved search in the Search tab, to change it
  var onEdit: (SavedSearch, Dashboard) -> Void

  @State private var dashboards: [Dashboard] = []
  @State private var pendingRename: Dashboard? = nil
  @State private var renameText = ""
  @State private var pendingDelete: Dashboard? = nil
  @State private var message: String? = nil

  private let manager = DashboardDataManager()

  var body: some View {
    Group {
      if let id = openDashboardId, let open = dashboards.first(where: { $0.id == id }) {
        macosDashboardView(dashboardId: id,
                           serverObjects: serverObjects,
                           onEdit: { search in onEdit(search, open) },
                           onBack: {
                             openDashboardId = nil
                             reload()
                           })
        .id(id)
      } else {
        list
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
      reload()
    }
    .alert(
      "Rename Dashboard",
      isPresented: Binding(
        get: { pendingRename != nil },
        set: { if !$0 { pendingRename = nil } }
      ),
      presenting: pendingRename
    ) { dashboard in
      TextField(dashboard.title, text: $renameText)
      Button("Cancel", role: .cancel) { }
      Button("Rename") {
        rename(dashboard, to: renameText)
      }
    }
    .alert(
      "Delete Dashboard?",
      isPresented: Binding(
        get: { pendingDelete != nil },
        set: { if !$0 { pendingDelete = nil } }
      ),
      presenting: pendingDelete
    ) { dashboard in
      Button("Cancel", role: .cancel) { }
      Button("Delete", role: .destructive) {
        manager.delete(id: dashboard.id)
        reload()
      }
    } message: { dashboard in
      Text("\"\(dashboard.title)\" will be deleted. Its saved searches stay in Saved.")
    }
  }

  private var list: some View {
    VStack(alignment: .leading, spacing: 10) {
      header

      if let message = message {
        Text(message)
          .font(.subheadline)
          .foregroundColor(Color("WarnText"))
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
      }

      if dashboards.isEmpty {
        emptyState
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(dashboards) { dashboard in
              macosDashboardRowView(dashboard: dashboard,
                                    onOpen: { openDashboardId = dashboard.id },
                                    onRename: {
                                      renameText = dashboard.title
                                      pendingRename = dashboard
                                    },
                                    onDelete: { pendingDelete = dashboard })
            }
          }
          .padding(.bottom, 10)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var header: some View {
    HStack(spacing: 6) {
      Text("Dashboards")
        .font(.system(size: 22, weight: .light))
      if !dashboards.isEmpty {
        Text("\(dashboards.count)")
          .font(.system(size: 12, weight: .semibold))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .foregroundColor(Color("TextSecondary"))
      }
      Spacer()
      if !dashboards.isEmpty {
        Button(action: create) {
          HStack(spacing: 4) {
            Image(systemName: "plus")
            Text("New Dashboard")
          }
        }
        .buttonStyle(macosDataViewButtonStyle())
        .help("Add an empty dashboard and open it")
      }
    }
    .padding(.top, 10)
    .padding(.bottom, 5)
  }

  private var emptyState: some View {
    VStack(spacing: 8) {
      Image(systemName: "square.grid.2x2")
        .font(.system(size: 28))
        .foregroundColor(Color("TextSecondary"))
      Text("No dashboards yet")
        .font(.headline)
      Text("A dashboard shows several saved searches side by side. Make one, then add searches you've saved from the Search tab.")
        .font(.subheadline)
        .foregroundColor(Color("TextSecondary"))
        .multilineTextAlignment(.center)
        .frame(maxWidth: 380)
      Button(action: create) {
        HStack(spacing: 4) {
          Image(systemName: "plus")
          Text("New Dashboard")
        }
      }
      .buttonStyle(macosDataViewButtonStyle())
      .padding(.top, 6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  // MARK: - Actions

  private func reload() {
    dashboards = manager.all()
    if let id = openDashboardId, !dashboards.contains(where: { $0.id == id }) {
      openDashboardId = nil
    }
  }

  private func create() {
    do {
      let dashboard = try manager.create()
      message = nil
      reload()
      openDashboardId = dashboard.id
    } catch {
      message = "The dashboard couldn't be made."
    }
  }

  private func rename(_ dashboard: Dashboard, to title: String) {
    do {
      try manager.rename(id: dashboard.id, title: title)
      message = nil
    } catch {
      message = "The dashboard couldn't be renamed."
    }
    reload()
  }
}

/// A dashboard in the list
struct macosDashboardRowView: View {
  var dashboard: Dashboard
  var onOpen: () -> Void
  var onRename: () -> Void
  var onDelete: () -> Void

  @State private var isHovered = false

  /// eg. "3 searches · refreshes every 5 minutes"
  var details: String {
    let count = dashboard.panels.count
    var parts = [count == 0 ? "No searches" : "\(count) \(count == 1 ? "search" : "searches")"]
    if dashboard.refreshSeconds > 0 {
      parts.append("refreshes every \(Dashboard.refreshTitle(dashboard.refreshSeconds))")
    }
    return parts.joined(separator: " · ")
  }

  var body: some View {
    Button(action: onOpen) {
      HStack(spacing: 10) {
        Image(systemName: "square.grid.2x2")
          .font(.system(size: 14))
          .foregroundColor(Color.accentColor)
          .frame(width: 20)

        VStack(alignment: .leading, spacing: 3) {
          Text(dashboard.title)
            .font(.system(size: 14, weight: .medium))
            .lineLimit(1)
            .truncationMode(.middle)
          Text(details)
            .font(.system(size: 11))
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
        }

        Spacer()

        Menu {
          menuItems
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color("TextSecondary"))
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More actions")

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(Color("TextSecondary"))
      }
      .padding(.vertical, 8)
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
    .contextMenu {
      menuItems
    }
    .help("Open this dashboard")
  }

  @ViewBuilder
  private var menuItems: some View {
    Button("Open", action: onOpen)
    Button("Rename…", action: onRename)
    Divider()
    Button("Delete…", role: .destructive, action: onDelete)
  }
}
#endif
