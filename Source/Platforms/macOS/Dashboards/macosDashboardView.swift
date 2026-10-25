// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

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
  /// Edit mode: panels can be moved, resized and removed. A dashboard always opens in view mode.
  @State private var isEditing = false
  /// Some panel is still searching, after a refresh or as the dashboard opens
  @State private var isRefreshing = false

  private let manager = DashboardDataManager()

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
          macosDashboardGridView(panels: dashboard.panels,
                                 isEditing: isEditing,
                                 onCommit: { frames in
                                   update { try manager.setLayout(id: dashboardId, frames: frames) }
                                 },
                                 onDoneEditing: { isEditing = false },
                                 panel: panelView)
            .onPreferenceChange(DashboardPanelLoadingKey.self) { isRefreshing = $0 }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .onAppear(perform: reload)
    // Nothing left to arrange
    .onChange(of: dashboard?.panels.isEmpty ?? true) { isEmpty in
      if isEmpty {
        isEditing = false
      }
    }
    .task(id: dashboard?.refreshSeconds ?? 0) {
      await autoRefresh(every: dashboard?.refreshSeconds ?? 0)
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

      if let dashboard = dashboard, !dashboard.panels.isEmpty {
        if isEditing {
          Text("Drag a title to move a panel, or an edge to resize it. Esc when done.")
            .font(.system(size: 11))
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
            .padding(.trailing, 4)
        }

        macosDashboardRefreshButton(isRefreshing: isRefreshing,
                                    seconds: dashboard.refreshSeconds,
                                    onRefresh: { refreshToken = UUID() },
                                    onSetInterval: { seconds in
                                      update { try manager.setRefreshInterval(id: dashboardId, seconds: seconds) }
                                    })

        addSearchButton

        Button {
          withAnimation(.easeOut(duration: 0.18)) {
            isEditing.toggle()
          }
        } label: {
          HStack(spacing: 4) {
            if !isEditing {
              Image(systemName: "pencil")
            }
            Text(isEditing ? "Done" : "Edit Layout")
          }
        }
        .buttonStyle(macosDataViewButtonStyle(confirmed: isEditing))
        .keyboardShortcut("e", modifiers: .command)
        .help(isEditing ? "Stop moving and resizing panels" : "Move, resize and remove panels")
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

  @ViewBuilder
  private func panelView(_ panel: DashboardPanel, moveHandle: macosDashboardMoveHandle) -> some View {
    if let search = searches[panel.savedSearchId] {
      macosDashboardPanelView(search: search,
                              host: host(id: search.hostId),
                              hostName: hostNames[search.hostId],
                              dataViewName: search.dataViewId.flatMap { dataViewNames[$0] },
                              rowLimit: panel.rowLimit,
                              frame: panel.frame,
                              refreshToken: refreshToken,
                              isEditing: isEditing,
                              columnWidths: panel.columnWidths,
                              onSetColumnWidths: { widths in
                                update { try manager.setColumnWidths(id: dashboardId, panelId: panel.id, widths: widths) }
                              },
                              moveHandle: moveHandle,
                              onEdit: { onEdit(search) },
                              onResize: { w, h in
                                update { try manager.setPanelSize(id: dashboardId, panelId: panel.id, w: w, h: h) }
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

  /// Adds the searches, then turns on edit mode so the new panels can be put in place
  private func add(_ ids: [UUID]) {
    addingSearches = false
    update { try manager.addPanels(id: dashboardId, savedSearchIds: ids) }
    if !ids.isEmpty && message == nil {
      isEditing = true
    }
  }

  private func remove(_ panel: DashboardPanel) {
    update { try manager.removePanel(id: dashboardId, panelId: panel.id) }
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

/// "Refresh" joined to a darker "⟳ Off" that chooses how often every panel searches again by itself. The menu's
/// label is an image and a single Text: a borderless menu only draws the first plain text of its label.
struct macosDashboardRefreshButton: View {
  var isRefreshing: Bool
  var seconds: Int
  var onRefresh: () -> Void
  var onSetInterval: (Int) -> Void

  @State private var hoveringRefresh = false
  @State private var hoveringInterval = false

  var body: some View {
    HStack(spacing: 0) {
      Button(action: onRefresh) {
        HStack(spacing: 4) {
          macosDashboardRefreshIcon(isSpinning: isRefreshing)
          Text("Refresh")
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(Color("TextColor"))
        .padding(.horizontal, 12)
        .frame(minHeight: 26)
        .background(hoveringRefresh ? Color("ButtonHighlighted") : Color("Button"))
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .onHover { hoveringRefresh = $0 }
      .keyboardShortcut("r", modifiers: .command)
      .help(isRefreshing ? "Searching… Click to run every search on this dashboard again"
                         : "Run every search on this dashboard again")

      Menu {
        Section("Auto Refresh") {
          ForEach(Dashboard.refreshIntervals, id: \.self) { option in
            Button {
              onSetInterval(option)
            } label: {
              if option == seconds {
                Label(Dashboard.refreshTitle(option), systemImage: "checkmark")
              } else {
                Text(Dashboard.refreshTitle(option))
              }
            }
          }
        }
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 11, weight: .medium))
          Text(Dashboard.shortRefreshTitle(seconds))
            .font(.system(size: 12, weight: .medium))
        }
      }
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
      // Green while auto refresh is on. A borderless menu ignores its label's foreground colour, but not a tint.
      .tint(seconds > 0 ? Color.green : nil)
      .fixedSize()
      .padding(.horizontal, 10)
      .frame(minHeight: 26)
      .background(hoveringInterval ? Color("ButtonHighlighted") : Color("BackgroundAlt"))
      .contentShape(Rectangle())
      .onHover { hoveringInterval = $0 }
      .help("Auto refresh: \(Dashboard.refreshTitle(seconds)). How often every search on this dashboard runs again.")
    }
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .animation(.easeInOut(duration: 0.15), value: hoveringRefresh)
    .animation(.easeInOut(duration: 0.15), value: hoveringInterval)
  }
}

/// The Refresh button's arrow, turning while any panel is still searching
struct macosDashboardRefreshIcon: View {
  var isSpinning: Bool

  var body: some View {
    TimelineView(.animation(paused: !isSpinning)) { context in
      Image(systemName: "arrow.clockwise")
        .rotationEffect(.degrees(isSpinning ? angle(at: context.date) : 0))
    }
  }

  /// One turn a second
  private func angle(at date: Date) -> Double {
    date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1) * 360
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
