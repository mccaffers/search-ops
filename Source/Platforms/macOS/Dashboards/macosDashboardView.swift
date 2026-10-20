// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)

/// One dashboard: its saved searches side by side in a grid
struct macosDashboardView: View {
  let dashboardId: UUID
  @ObservedObject var serverObjects: HostsDataManager
  /// Opens a panel's saved search in the Search tab
  var onEdit: (SavedSearch) -> Void
  var onBack: () -> Void

  @State private var dashboard: Dashboard? = nil
  /// Every saved search, by id, for the panels and the Add Search list
  @State private var searches: [UUID: SavedSearch] = [:]
  @State private var dataViewNames: [UUID: String] = [:]
  @State private var addingSearches = false
  @State private var message: String? = nil
  /// Replaced to make every panel search again
  @State private var refreshToken = UUID()
  /// The panel being dragged to a new place
  @State private var dragging: UUID? = nil

  private let manager = DashboardDataManager()

  static let gridSpacing: CGFloat = 10

  private var hostNames: [UUID: String] {
    Dictionary(serverObjects.items.filter { !$0.isInvalidated }.map { ($0.id, $0.name) },
               uniquingKeysWith: { first, _ in first })
  }

  /// Saved searches for the Add Search list, grouped by host as in the Saved tab
  private var searchGroups: [SavedDocumentGroup] {
    let hosts = serverObjects.items.filter { !$0.isInvalidated }.map { (id: $0.id, name: $0.name) }
    let sorted = searches.values.sorted { $0.savedDate > $1.savedDate }
    return SavedDocument.grouped([], searches: sorted, hosts: hosts)
  }

  var body: some View {
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

      if let dashboard = dashboard {
        if dashboard.panels.isEmpty {
          emptyState
        } else {
          layoutBar(dashboard)

          ScrollView {
            grid(dashboard)
              .padding(.bottom, 10)
          }
          // Dropped between panels, or outside them
          .onDrop(of: [UTType.text], delegate: macosDashboardDropOutsideDelegate(dragging: $dragging))
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .onAppear(perform: reload)
    .task(id: dashboard?.refreshSeconds ?? 0) {
      await autoRefresh(every: dashboard?.refreshSeconds ?? 0)
    }
  }

  /// Columns and auto refresh, under the title
  private func layoutBar(_ dashboard: Dashboard) -> some View {
    HStack(spacing: 10) {
      HStack(spacing: 6) {
        Text("Columns")
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary"))
        HStack(spacing: 2) {
          ForEach(Array(Dashboard.columnRange), id: \.self) { count in
            macosSettingsSegment(title: "\(count)", selected: dashboard.columns == count) {
              update { try manager.setColumns(id: dashboardId, columns: count) }
            }
          }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 5).fill(Color("Button")))
      }

      macosDashboardRefreshMenu(seconds: dashboard.refreshSeconds) { seconds in
        update { try manager.setRefreshInterval(id: dashboardId, seconds: seconds) }
      }

      Spacer()

      Text("Drag a panel to move it")
        .font(.system(size: 11))
        .foregroundColor(Color("TextSecondary"))
    }
  }

  private var header: some View {
    HStack(spacing: 8) {
      macosDashboardBackButton(action: onBack)

      Text(dashboard?.title ?? "")
        .font(.system(size: 22, weight: .light))
        .lineLimit(1)
        .truncationMode(.middle)

      Spacer()

      if dashboard?.panels.isEmpty == false {
        Button {
          refreshToken = UUID()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "arrow.clockwise")
            Text("Refresh")
          }
        }
        .buttonStyle(macosDataViewButtonStyle())
        .keyboardShortcut("r", modifiers: .command)
        .help("Run every search on this dashboard again")

        addSearchButton
      }
    }
    .padding(.top, 10)
    .padding(.bottom, 5)
  }

  private var addSearchButton: some View {
    Button {
      addingSearches = true
    } label: {
      HStack(spacing: 4) {
        Image(systemName: "plus")
        Text("Add Search")
      }
    }
    .buttonStyle(macosDataViewButtonStyle())
    .help("Add saved searches to this dashboard")
    .popover(isPresented: $addingSearches, arrowEdge: .bottom) {
      macosDashboardAddSearchPopover(groups: searchGroups,
                                     shownIds: Set(dashboard?.savedSearchIds ?? []),
                                     dataViewNames: dataViewNames,
                                     onAdd: add,
                                     onCancel: { addingSearches = false })
    }
  }

  private var emptyState: some View {
    VStack(spacing: 8) {
      Image(systemName: "square.grid.2x2")
        .font(.system(size: 28))
        .foregroundColor(Color("TextSecondary"))
      Text("This dashboard is empty")
        .font(.headline)
      Text(searches.isEmpty
           ? "Save a search from the Search tab first, then add it here."
           : "Add saved searches to see them side by side.")
        .font(.subheadline)
        .foregroundColor(Color("TextSecondary"))
        .multilineTextAlignment(.center)
        .frame(maxWidth: 380)
      if !searches.isEmpty {
        addSearchButton
          .padding(.top, 6)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  /// The panels in rows of the dashboard's number of columns, full width panels on rows of their own
  private func grid(_ dashboard: Dashboard) -> some View {
    let rows = Dashboard.rows(dashboard.panels, columns: dashboard.columns)
    return VStack(spacing: Self.gridSpacing) {
      ForEach(rows, id: \.first?.id) { row in
        HStack(alignment: .top, spacing: Self.gridSpacing) {
          ForEach(row) { panel in
            panelView(panel)
              .opacity(dragging == panel.id ? 0.5 : 1)
              .onDrag {
                dragging = panel.id
                return NSItemProvider(object: panel.id.uuidString as NSString)
              }
              .onDrop(of: [UTType.text],
                      delegate: macosDashboardDropDelegate(target: panel.id,
                                                           dragging: $dragging,
                                                           onMove: move))
          }
          // Keeps a short row's panels the same width as the rest
          if row.first?.width != .full {
            ForEach(row.count..<dashboard.columns, id: \.self) { _ in
              Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
            }
          }
        }
      }
    }
    .animation(.default, value: dashboard.panels)
  }

  @ViewBuilder
  private func panelView(_ panel: DashboardPanel) -> some View {
    if let search = searches[panel.savedSearchId] {
      macosDashboardPanelView(search: search,
                              host: host(id: search.hostId),
                              hostName: hostNames[search.hostId],
                              dataViewName: search.dataViewId.flatMap { dataViewNames[$0] },
                              rowLimit: panel.height.rowLimit,
                              width: panel.width,
                              height: panel.height,
                              refreshToken: refreshToken,
                              onEdit: { onEdit(search) },
                              onResize: { width, height in
                                update { try manager.setPanelSize(id: dashboardId, panelId: panel.id,
                                                                  width: width, height: height) }
                              },
                              onRemove: { remove(panel) })
    }
  }

  // MARK: - Actions

  private func host(id: UUID) -> HostDetails? {
    guard let host = serverObjects.getHostByID(id), !host.isInvalidated else { return nil }
    return host
  }

  private func reload() {
    let all = SavedSearchDataManager().all()
    searches = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    // Panels for searches deleted while the tab wasn't watching
    manager.pruneMissingSearches(validSearchIds: Set(searches.keys))
    dashboard = manager.dashboard(id: dashboardId)
    let dataViews = DataViewDataManager()
    var names: [UUID: String] = [:]
    for id in Set(all.compactMap(\.dataViewId)) {
      if let view = dataViews.view(id: id) {
        names[id] = view.name
      }
    }
    dataViewNames = names
  }

  private func add(_ ids: [UUID]) {
    addingSearches = false
    update { try manager.addPanels(id: dashboardId, savedSearchIds: ids) }
  }

  private func remove(_ panel: DashboardPanel) {
    update { try manager.removePanel(id: dashboardId, panelId: panel.id) }
  }

  /// Puts the dragged panel in the place of the one it's over, saving the order straight away
  private func move(_ moving: UUID, onto target: UUID) {
    guard let dashboard = dashboard else { return }
    let ids = dashboard.panels.map(\.id)
    let reordered = Dashboard.reordered(ids, moving: moving, onto: target)
    guard reordered != ids else { return }
    update { try manager.setPanelOrder(id: dashboardId, panelIds: reordered) }
  }

  /// Makes every panel search again every `seconds`, until the interval changes or the dashboard closes
  private func autoRefresh(every seconds: Int) async {
    guard seconds > 0 else { return }
    while !Task.isCancelled {
      try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
      if Task.isCancelled { break }
      refreshToken = UUID()
    }
  }

  /// Saves a change and shows the dashboard as it then is
  private func update(_ change: () throws -> Dashboard) {
    do {
      dashboard = try change()
      message = nil
    } catch {
      message = "The dashboard couldn't be changed."
    }
  }
}

/// Moves the dragged panel as it passes over another
struct macosDashboardDropDelegate: DropDelegate {
  let target: UUID
  @Binding var dragging: UUID?
  var onMove: (UUID, UUID) -> Void

  func dropEntered(info: DropInfo) {
    if let dragging = dragging, dragging != target {
      onMove(dragging, target)
    }
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    DropProposal(operation: .move)
  }

  func performDrop(info: DropInfo) -> Bool {
    dragging = nil
    return true
  }
}

/// Ends a drag that's let go away from a panel. The order was saved as the panel moved.
struct macosDashboardDropOutsideDelegate: DropDelegate {
  @Binding var dragging: UUID?

  func dropUpdated(info: DropInfo) -> DropProposal? {
    DropProposal(operation: .move)
  }

  func performDrop(info: DropInfo) -> Bool {
    dragging = nil
    return true
  }
}

/// "Auto refresh: Off", choosing how often every panel searches again
struct macosDashboardRefreshMenu: View {
  var seconds: Int
  var onChange: (Int) -> Void

  @State private var hovering = false

  var body: some View {
    Menu {
      ForEach(Dashboard.refreshIntervals, id: \.self) { option in
        Button {
          onChange(option)
        } label: {
          if option == seconds {
            Label(Dashboard.refreshTitle(option), systemImage: "checkmark")
          } else {
            Text(Dashboard.refreshTitle(option))
          }
        }
      }
    } label: {
      HStack(spacing: 4) {
        Text("Auto refresh:")
          .foregroundColor(Color("TextSecondary"))
        Text(Dashboard.refreshTitle(seconds))
          .foregroundColor(Color("TextColor"))
        Image(systemName: "chevron.down")
          .font(.system(size: 9, weight: .semibold))
          .foregroundColor(Color("TextSecondary"))
      }
      .font(.system(size: 12))
      .padding(.horizontal, 8)
      .frame(minHeight: 28)
      .background(RoundedRectangle(cornerRadius: 5).fill(hovering ? Color("ButtonHighlighted") : Color("Button")))
      .contentShape(Rectangle())
    }
    .menuStyle(.borderlessButton)
    .menuIndicator(.hidden)
    .fixedSize()
    .onHover { hovering = $0 }
    .help("How often every search on this dashboard runs again")
  }
}

/// "‹", back to the list, like the back buttons in the Hosts views
struct macosDashboardBackButton: View {
  var action: () -> Void

  @State private var hovering = false

  var body: some View {
    Button(action: action) {
      Image(systemName: "chevron.left")
        .font(.system(size: 20, weight: .semibold))
        .padding(8)
        .background(hovering ? Color("ButtonHighlighted") : Color.clear)
        .clipShape(.rect(cornerRadius: 4))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering = $0 }
    .help("Back to the list of dashboards")
  }
}
#endif
