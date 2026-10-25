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
  /// Its place on the grid, for the size choices in its edit mode menu
  var frame: DashboardGridFrame
  /// Changes when the dashboard is refreshed
  var refreshToken: UUID
  /// Edit mode: shows the Edit and Remove buttons, right-clicking the header sizes the panel, and column borders can
  /// be dragged
  var isEditing: Bool
  /// Column widths set on this panel, by `DashboardColumn.savedKey`
  var columnWidths: [String: Double]
  var onSetColumnWidths: ([String: Double]) -> Void
  /// Dragging the header moves the panel
  var moveHandle: macosDashboardMoveHandle
  var onEdit: () -> Void
  /// A new width in columns and height in rows
  var onResize: (Int, Int) -> Void
  var onRemove: () -> Void

  /// Around the panel's contents. The grid lines its resize arrows up with it.
  static let padding: CGFloat = 12
  static let footerHeight: CGFloat = 14

  @State private var result: DashboardPanelResult? = nil
  @State private var isLoading = false
  @State private var lastRun: Date? = nil
  @State private var hoveringTitle = false
  @State private var hoveringGrip = false
  /// Each column fitted to the documents found, measured once per search
  @State private var automaticWidths: [DashboardColumn: Double] = [:]

  /// What the panel's search depends on. A change searches again, cancelling a search still going.
  struct RunKey: Equatable {
    let search: SavedSearch
    let rowLimit: Int
    let refresh: UUID
  }

  private var runKey: RunKey {
    RunKey(search: search, rowLimit: rowLimit, refresh: refreshToken)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
      footer
    }
    .padding(Self.padding)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 5).fill(Color("Button")))
    .overlay(alignment: .top) {
      if moveHandle.isEnabled {
        grip
      }
    }
    .onChange(of: moveHandle.isEnabled) { isEnabled in
      // Edit mode ended under the pointer, so the hand it pushed has to go
      if !isEnabled && hoveringGrip {
        hoveringGrip = false
        NSCursor.pop()
      }
    }
    .task(id: runKey) {
      await run()
    }
    .preference(key: DashboardPanelLoadingKey.self, value: isLoading)
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
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.trailing, 8)
      // The title and the space beside it are the handle the panel is dragged by
      .contentShape(Rectangle())
      .onHover { inside in
        // Only pops the hand it pushed
        let showHand = inside && moveHandle.isEnabled
        guard showHand != hoveringTitle else { return }
        hoveringTitle = showHand
        if showHand {
          NSCursor.openHand.push()
        } else {
          NSCursor.pop()
        }
      }
      .gesture(moveHandle.gesture, including: moveHandle.isEnabled ? .all : .subviews)

      if isEditing {
        Button("Edit", action: onEdit)
          .buttonStyle(macosDataViewButtonStyle())
          .disabled(host == nil)
          .help(host == nil
                ? "The host this search was saved from no longer exists"
                : "Open this search in the Search tab to change it")
        Button("Remove", action: onRemove)
          .buttonStyle(macosDataViewButtonStyle(destructive: true))
          .help("Remove this search from the dashboard")
      }
    }
    .modifier(macosDashboardPanelSizeMenu(isEnabled: isEditing) {
      SwiftUI.Picker("Width", selection: Binding(get: { frame.w }, set: { onResize($0, frame.h) })) {
        ForEach(DashboardLayout.widthPresets, id: \.w) { option in
          Text(option.title).tag(option.w)
        }
      }
      SwiftUI.Picker("Height", selection: Binding(get: { frame.h }, set: { onResize(frame.w, $0) })) {
        ForEach(DashboardLayout.heightPresets, id: \.documents) { option in
          Text("\(option.title), \(option.documents) documents").tag(DashboardLayout.height(fitting: option.documents))
        }
      }
      Button("Reset Column Widths") { onSetColumnWidths([:]) }
        .disabled(columnWidths.isEmpty)
    })
  }

  /// Three lines along the top edge in edit mode, showing the panel can be dragged by its header. They light up
  /// while the header is hovered or the panel is moving, and can be dragged themselves.
  private var grip: some View {
    let highlighted = hoveringTitle || hoveringGrip || moveHandle.isMoving
    return Image(systemName: "line.3.horizontal")
      .font(.system(size: 11, weight: .semibold))
      .foregroundColor(Color(highlighted ? "TextColor" : "TextSecondary"))
      .frame(width: 88, height: 12)
      .background(RoundedRectangle(cornerRadius: 5).fill(highlighted ? Color("ButtonHighlighted") : Color.clear))
      .contentShape(Rectangle())
      .onHover { inside in
        guard inside != hoveringGrip else { return }
        hoveringGrip = inside
        if inside {
          NSCursor.openHand.push()
        } else {
          NSCursor.pop()
        }
      }
      .gesture(moveHandle.gesture)
      .help("Drag to move this panel")
  }

  @ViewBuilder
  private var content: some View {
    if let result = result, let error = result.error {
      VStack(spacing: 6) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 22))
          .foregroundColor(.red)
          .padding(.bottom, 2)
        Text(error.title)
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(Color("TextColor"))
        Text(error.message)
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary"))
          .multilineTextAlignment(.center)
          .lineLimit(4)
          .textSelection(.enabled)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .frame(maxWidth: 420)
      .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if let result = result {
      if result.rows.isEmpty {
        Text(search.period == nil ? "No documents found" : "No documents in this time period")
          .font(.subheadline)
          .foregroundColor(Color("TextSecondary"))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        let preferred = DashboardColumnWidths.preferred(columns: result.columns,
                                                        automatic: automaticWidths,
                                                        search: search.columnWidths,
                                                        panel: columnWidths)
        macosDashboardTableView(columns: result.columns,
                                rows: result.rows,
                                rowLimit: rowLimit,
                                preferredWidths: preferred.widths,
                                setColumns: preferred.set,
                                isEditing: isEditing,
                                onResizeColumn: { column, width in
                                  var widths = columnWidths
                                  widths[column.savedKey] = width
                                  onSetColumnWidths(widths)
                                },
                                onFitColumns: { fitColumns(result) })
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
    .frame(minHeight: Self.footerHeight)
    // Room for the resize arrows the grid puts on this line in edit mode
    .padding(.trailing, moveHandle.isEnabled ? 22 : 0)
  }

  /// Every column but the last, which fills the row, sized to its whole header and documents
  private func fitColumns(_ result: DashboardPanelResult) {
    let fitted = DashboardColumnWidths.fittedToContents(columns: Array(result.columns.dropLast()),
                                                        rows: Array(result.rows.prefix(rowLimit))) {
      Double(macosTableSearchView.measureText($0, bold: $1))
    }
    onSetColumnWidths(columnWidths.merging(fitted) { _, new in new })
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
    automaticWidths = DashboardColumnWidths.automatic(columns: found.columns, rows: Array(found.rows.prefix(rowLimit))) {
      Double(macosTableSearchView.measureText($0, bold: $1))
    }
    result = found
    lastRun = Date.now
    isLoading = false
  }
}

/// True while any panel on the dashboard is searching, so the Refresh button can show it
struct DashboardPanelLoadingKey: PreferenceKey {
  static let defaultValue = false

  static func reduce(value: inout Bool, nextValue: () -> Bool) {
    value = value || nextValue()
  }
}

/// Right-clicking a panel's header in edit mode offers its sizes and resets its column widths
private struct macosDashboardPanelSizeMenu<Items: View>: ViewModifier {
  var isEnabled: Bool
  @ViewBuilder var items: Items

  func body(content: Content) -> some View {
    if isEnabled {
      content.contextMenu { items }
    } else {
      content
    }
  }
}
#endif
