// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

/// A saved search on a dashboard: its first few documents as a table, searched as the panel appears and each time
/// the dashboard refreshes
struct macosDashboardPanelView: View {
  var search: SavedSearch
  /// nil once the host is deleted. Only read as a search starts, a copy goes into the search.
  var host: HostDetails?
  var hostName: String?
  /// The data view it was saved from, nil when there's none or it's been deleted
  var dataViewName: String?
  var rowLimit: Int
  var width: DashboardPanelWidth
  var height: DashboardPanelHeight
  /// Changes when the dashboard is refreshed
  var refreshToken: UUID
  var onEdit: () -> Void
  var onResize: (DashboardPanelWidth, DashboardPanelHeight) -> Void
  var onRemove: () -> Void

  @State private var result: DashboardPanelResult? = nil
  @State private var isLoading = false
  @State private var lastRun: Date? = nil
  /// Replaced to search again from the panel's menu
  @State private var panelRefresh = UUID()

  /// What the panel's search depends on. A change searches again, cancelling a search still going.
  struct RunKey: Equatable {
    let search: SavedSearch
    let rowLimit: Int
    let refresh: [UUID]
  }

  private var runKey: RunKey {
    RunKey(search: search, rowLimit: rowLimit, refresh: [refreshToken, panelRefresh])
  }

  /// eg. "Production · logs-* · Last hour"
  var subtitle: String {
    var parts = [String]()
    if let hostName = hostName {
      parts.append(hostName)
    }
    parts.append(dataViewName ?? search.searchIndex)
    if let period = search.periodTitle {
      parts.append(period)
    }
    return parts.joined(separator: " · ")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      header
      content
        .frame(height: macosDashboardTableView.height(rowLimit: rowLimit))
      footer
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 5).fill(Color("Button")))
    .task(id: runKey) {
      await run()
    }
  }

  private var header: some View {
    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(search.displayTitle)
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color("TextColor"))
          .lineLimit(1)
          .truncationMode(.middle)
        Text(subtitle)
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
          .truncationMode(.middle)
      }
      .help(search.query.isEmpty ? search.displayTitle : "\(search.displayTitle)\n\(search.query)")

      Spacer(minLength: 8)

      Button("Edit", action: onEdit)
        .buttonStyle(macosDataViewButtonStyle())
        .disabled(host == nil)
        .help(host == nil
              ? "The host this search was saved from no longer exists"
              : "Open this search in the Search tab to change it")

      macosDashboardMenuButton {
        Button("Refresh") { panelRefresh = UUID() }
        Button("Edit in Search", action: onEdit)
          .disabled(host == nil)
        Divider()
        SwiftUI.Picker("Width", selection: Binding(get: { width }, set: { onResize($0, height) })) {
          ForEach(DashboardPanelWidth.allCases, id: \.self) { option in
            Text(option.title).tag(option)
          }
        }
        SwiftUI.Picker("Height", selection: Binding(get: { height }, set: { onResize(width, $0) })) {
          ForEach(DashboardPanelHeight.allCases, id: \.self) { option in
            Text("\(option.title), \(option.rowLimit) documents").tag(option)
          }
        }
        Divider()
        Button("Remove from Dashboard", role: .destructive, action: onRemove)
      }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let result = result, let error = result.error {
      VStack(alignment: .leading, spacing: 4) {
        Text(error.title)
          .font(.system(size: 12, weight: .semibold))
        Text(error.message)
          .font(.system(size: 12))
          .lineLimit(4)
          .textSelection(.enabled)
      }
      .foregroundColor(Color("WarnText"))
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    } else if let result = result {
      if result.rows.isEmpty {
        Text(search.period == nil ? "No documents found" : "No documents in this time period")
          .font(.subheadline)
          .foregroundColor(Color("TextSecondary"))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        macosDashboardTableView(columns: result.columns, rows: result.rows, rowLimit: rowLimit)
          .opacity(isLoading ? 0.6 : 1)
      }
    } else {
      ProgressView()
        .controlSize(.small)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private var footer: some View {
    HStack(spacing: 6) {
      if let result = result, result.error == nil {
        Text(SearchResult.hitCountLabel(result.hits, isLowerBound: result.hitsIsLowerBound))
          .monospacedDigit()
      }
      if let duration = result?.duration {
        Text(duration.latencyLabel)
          .monospacedDigit()
          .foregroundColor(duration.isSlowLatency ? .orange : Color("TextSecondary"))
      }
      Spacer()
      if isLoading && result != nil {
        ProgressView()
          .controlSize(.mini)
      }
      if let lastRun = lastRun {
        Text("Updated \(lastRun.formatted(date: .omitted, time: .standard))")
          .monospacedDigit()
      }
    }
    .font(.system(size: 11))
    .foregroundColor(Color("TextSecondary"))
    .frame(minHeight: 14)
  }

  /// Searches for the panel's documents, waiting its turn so a big dashboard doesn't search all at once
  private func run() async {
    guard let host = host, !host.isInvalidated else {
      result = DashboardPanelResult(error: ResponseError(title: "Host not found",
                                                         message: "The host this search was saved from no longer exists.",
                                                         type: .critical))
      isLoading = false
      return
    }
    isLoading = true
    let copy = host.generateCopy()
    let dataView = search.dataViewId.flatMap { DataViewDataManager().view(id: $0) }
    let search = search
    let rowLimit = rowLimit
    let found = await DashboardSearchQueue.shared.run {
      await DashboardPanelSearch.run(search, host: copy, dataView: dataView, rowLimit: rowLimit)
    }
    // A newer search took over, or the panel went away
    guard let found = found, !Task.isCancelled else { return }
    result = found
    lastRun = Date.now
    isLoading = false
  }
}

/// "…" opening a panel's menu, filled on hover
struct macosDashboardMenuButton<Items: View>: View {
  @ViewBuilder var items: Items

  @State private var hovering = false

  var body: some View {
    Menu {
      items
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color(hovering ? "TextColor" : "TextSecondary"))
        .frame(width: 24, height: 24)
        .background(RoundedRectangle(cornerRadius: 5).fill(hovering ? Color("ButtonHighlighted") : Color.clear))
        .contentShape(Rectangle())
    }
    .menuStyle(.borderlessButton)
    .menuIndicator(.hidden)
    .fixedSize()
    .onHover { hovering = $0 }
    .help("More actions")
  }
}
#endif
