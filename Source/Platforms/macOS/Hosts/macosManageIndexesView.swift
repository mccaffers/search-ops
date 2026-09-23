// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
struct macosManageIndexesView: View {
  var host: HostDetails
  var onBack: () -> Void
  var onSelectIndex: ((String, IndexStatsItem?) -> Void)? = nil

  @State private var indexArray: [String] = []
  @State private var hiddenIndexArray: [String] = []
  @AppStorage("manageIndexes.showHidden") private var showHiddenIndices: Bool = false
  @State private var indexStats: [String: IndexStatsItem] = [:]
  @State private var isToggleHovered: Bool = false
  @State private var statsTask: Task<Void, Never>? = nil
  @State private var loading: Bool = true
  @State private var indexError: ResponseError? = nil
  @State private var searchText: String = ""
  @State private var isBackHovered: Bool = false

  @State private var sortOption: ManageIndexesSortOption = .name
  @State private var sortAscending: Bool = true
  @State private var isLoadingRecent: Bool = false
  @State private var hasFetchedRecent: Bool = false
  @State private var cachedTimestamps: [String: Double] = [:]
  @State private var recentSortTask: Task<Void, Never>? = nil
  @State private var sortStatusMessage: String? = nil

  var allCurrentIndices: [String] {
    showHiddenIndices ? (indexArray + hiddenIndexArray) : indexArray
  }

  var filteredIndices: [String] {
    let filtered = IndexFilterHelper.filter(indices: allCurrentIndices, query: searchText, preserveOrder: true)
    return ManageIndexesSortHelper.sortIndices(
      indices: filtered,
      sortOption: sortOption,
      ascending: sortAscending,
      stats: indexStats,
      timestamps: cachedTimestamps
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Top-left header with back button and index count
      HStack(spacing: 8) {
        Button(action: onBack) {
          Image(systemName: "chevron.left")
            .font(.system(size: 20, weight: .semibold))
            .padding(8)
            .background(isBackHovered ? Color("ButtonHighlighted") : Color.clear)
            .clipShape(.rect(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isBackHovered = hovering
        }
        .help("Back to host options")

        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text("Indexes")
              .font(.system(size: 20, weight: .light))
            if !loading && indexError == nil {
              Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(allCurrentIndices.count)" : "\(filteredIndices.count) / \(allCurrentIndices.count)")
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color("Button"))
                .clipShape(Capsule())
                .foregroundColor(Color("TextSecondary"))
            }
          }
          if !host.isInvalidated {
            Text(host.name)
              .font(.subheadline)
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
          }
        }

        Spacer()
      }
      .padding(.top, 10)
      .padding(.bottom, 2)

      // Content Area
      if loading {
        RepeatedPlaceholderView()
        Spacer()
      } else if let indexError = indexError {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
            Text(indexError.title)
              .font(.headline)
          }
          Text(indexError.message)
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))

          Button(action: {
            Task {
              await fetchIndices()
            }
          }) {
            HStack(spacing: 4) {
              Image(systemName: "arrow.clockwise")
              Text("Retry")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundFixedShadow"))
        .clipShape(.rect(cornerRadius: 5))

        Spacer()
      } else if indexArray.isEmpty && hiddenIndexArray.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "tray")
            .font(.system(size: 28))
            .foregroundColor(Color("TextSecondary"))
          Text("No indices found")
            .font(.headline)
          Text("No indices were returned for this host.")
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
      } else {
        // Search filter & Hidden toggle bar
        HStack(spacing: 8) {
          HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(Color("TextSecondary"))
              .font(.system(size: 12))

            TextField("Filter indices...", text: $searchText)
              .textFieldStyle(PlainTextFieldStyle())
              .font(.system(size: 13))
              .disableAutocorrection(true)
              .onExitCommand {
                searchText = ""
              }

            if !searchText.isEmpty {
              Button(action: { searchText = "" }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(Color("TextSecondary"))
                  .font(.system(size: 12))
              }
              .buttonStyle(PlainButtonStyle())
              .help("Clear filter")
            }
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))

          // Toggle Hidden Indices Button opposite search index field
          Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
              showHiddenIndices.toggle()
            }
          }) {
            HStack(spacing: 5) {
              Image(systemName: showHiddenIndices ? "eye" : "eye.slash")
                .font(.system(size: 11, weight: .medium))
              Text("Hidden")
                .font(.system(size: 12, weight: .medium))
              if !hiddenIndexArray.isEmpty {
                Text("\(hiddenIndexArray.count)")
                  .font(.system(size: 10, weight: .semibold))
                  .padding(.horizontal, 5)
                  .padding(.vertical, 1)
                  .background(showHiddenIndices ? Color.accentColor.opacity(0.25) : Color("BackgroundFixedShadow"))
                  .clipShape(Capsule())
              }
            }
            .foregroundColor(showHiddenIndices ? .primary : Color("TextSecondary"))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(showHiddenIndices ? (isToggleHovered ? Color("ButtonHighlighted") : Color("ButtonHighlighted").opacity(0.7)) : (isToggleHovered ? Color("ButtonHighlighted") : Color("Button")))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .onHover { hovering in
            isToggleHovered = hovering
          }
          .help(showHiddenIndices ? "Hide system and hidden indices" : "Show system and hidden indices (prefixed with .)")
        }

        // Sort options bar
        HStack(spacing: 5) {
          Text("Sort:")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color("TextSecondary"))

          ForEach(ManageIndexesSortOption.allCases) { option in
            macosManageIndexesSortButton(
              option: option,
              isSelected: sortOption == option,
              isAscending: sortAscending,
              isLoading: option == .recent && isLoadingRecent,
              action: {
                handleSortOptionSelected(option)
              }
            )
          }

          if let statusMessage = sortStatusMessage, sortOption == .recent {
            HStack(spacing: 3) {
              Text(statusMessage)
                .font(.system(size: 10))
                .foregroundColor(Color("TextSecondary"))
                .lineLimit(1)

              Button(action: {
                triggerFetchRecentActivity()
              }) {
                Image(systemName: "arrow.clockwise")
                  .font(.system(size: 9))
                  .foregroundColor(Color("TextSecondary"))
              }
              .buttonStyle(PlainButtonStyle())
              .help("Retry fetching recent activity")
            }
            .help(statusMessage)
          }

          Spacer()
        }

        // Index list & Empty states
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !showHiddenIndices && indexArray.isEmpty && !hiddenIndexArray.isEmpty && trimmedSearch.isEmpty {
          VStack(spacing: 8) {
            Image(systemName: "eye.slash")
              .font(.system(size: 28))
              .foregroundColor(Color("TextSecondary"))
            Text("No visible indices")
              .font(.headline)
            Text("This host only contains hidden or system indices.")
              .font(.subheadline)
              .foregroundColor(Color("TextSecondary"))
            Button(action: {
              withAnimation(.easeInOut(duration: 0.15)) {
                showHiddenIndices = true
              }
            }) {
              HStack(spacing: 4) {
                Image(systemName: "eye")
                Text("Show hidden indices (\(hiddenIndexArray.count))")
              }
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .background(Color("Button"))
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.top, 40)
        } else if filteredIndices.isEmpty {
          let hiddenMatches = IndexFilterHelper.filter(indices: hiddenIndexArray, query: searchText)
          if !showHiddenIndices && !hiddenMatches.isEmpty {
            VStack(spacing: 8) {
              Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(Color("TextSecondary"))
              Text("No matching visible indices")
                .font(.headline)
              let count = hiddenMatches.count
              let matchText = count == 1 ? "1 hidden index matches your search" : "\(count) hidden indices match your search"
              Text(matchText)
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
              Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                  showHiddenIndices = true
                }
              }) {
                HStack(spacing: 4) {
                  Image(systemName: "eye")
                  Text(count == 1 ? "Reveal hidden index (1)" : "Reveal hidden indices (\(count))")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color("Button"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(Rectangle())
              }
              .buttonStyle(PlainButtonStyle())
              .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
          } else {
            VStack(spacing: 8) {
              Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(Color("TextSecondary"))
              Text("No matching indices")
                .font(.headline)
              Text("No indices match \"\(searchText)\".")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
          }
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
              ForEach(filteredIndices, id: \.self) { indexName in
                macosManageIndexRowView(
                  indexName: indexName,
                  stats: indexStats[indexName],
                  activityTimestamp: cachedTimestamps[indexName],
                  onSelect: {
                    onSelectIndex?(indexName, indexStats[indexName])
                  }
                )
              }
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .task {
      await fetchIndices()
    }
    .onDisappear {
      statsTask?.cancel()
      statsTask = nil
      recentSortTask?.cancel()
      recentSortTask = nil
      isLoadingRecent = false
    }
  }

  private func handleSortOptionSelected(_ option: ManageIndexesSortOption) {
    if option == sortOption {
      if option == .recent && isLoadingRecent {
        recentSortTask?.cancel()
        recentSortTask = nil
        isLoadingRecent = false
        return
      }
      if option == .recent && !hasFetchedRecent && !isLoadingRecent {
        triggerFetchRecentActivity()
        return
      }
      withAnimation(.easeInOut(duration: 0.15)) {
        sortAscending.toggle()
      }
    } else {
      if isLoadingRecent {
        recentSortTask?.cancel()
        recentSortTask = nil
        isLoadingRecent = false
      }
      withAnimation(.easeInOut(duration: 0.15)) {
        sortOption = option
        sortAscending = option.defaultAscending
      }
      if option == .recent && !hasFetchedRecent {
        triggerFetchRecentActivity()
      }
    }
  }

  @MainActor
  private func triggerFetchRecentActivity() {
    recentSortTask?.cancel()
    recentSortTask = nil

    guard !host.isInvalidated else { return }

    isLoadingRecent = true
    sortStatusMessage = nil

    let detachedHost = host.generateCopy()
    let targets = indexArray + hiddenIndexArray

    recentSortTask = Task { @MainActor in
      let result = await IndexActivityService.fetchIndicesActivity(
        serverDetails: detachedHost,
        indices: targets
      )

      guard !Task.isCancelled else { return }

      isLoadingRecent = false
      hasFetchedRecent = true
      recentSortTask = nil

      if let errorMsg = result.errorMessage {
        sortStatusMessage = errorMsg
      }

      withAnimation(.easeInOut(duration: 0.2)) {
        self.cachedTimestamps = result.timestamps
      }
    }
  }

  @MainActor
  private func fetchIndices() async {
    statsTask?.cancel()
    statsTask = nil
    recentSortTask?.cancel()
    recentSortTask = nil
    isLoadingRecent = false
    hasFetchedRecent = false
    cachedTimestamps = [:]
    sortStatusMessage = nil

    loading = true
    indexError = nil
    indexArray = []
    hiddenIndexArray = []
    indexStats = [:]

    guard !host.isInvalidated else {
      indexError = ResponseError(title: "Host Invalidated", message: "The host has been removed or invalidated.", type: .critical)
      loading = false
      return
    }

    let detachedHost = host.generateCopy()
    let response = await Indicies.listIndexes(serverDetails: detachedHost)

    guard !Task.isCancelled else { return }

    if let error = response.error {
      indexError = error
      loading = false
      return
    }

    if response.httpStatus >= 400 {
      let rawMessage = response.parsed?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let displayMessage = rawMessage.isEmpty ? "Request failed with HTTP status \(response.httpStatus)" : rawMessage
      indexError = ResponseError(title: "HTTP Error \(response.httpStatus)", message: displayMessage, type: .critical)
      loading = false
      return
    }

    guard let parsed = response.parsed, !parsed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      indexError = ResponseError(title: "Response Error", message: "No data received", type: .critical)
      loading = false
      return
    }

    let indexResult = Results.getIndexArray(parsed)
    if let error = indexResult.error {
      indexError = ResponseError(title: "Index Error", message: error, type: .critical)
    } else if JsonTools.serialiseJson(parsed) == nil {
      indexError = ResponseError(title: "Response Error", message: "Invalid JSON response received from host", type: .critical)
    } else {
      indexArray = indexResult.data
      hiddenIndexArray = indexResult.hiddenData
    }
    loading = false

    if indexError == nil {
      statsTask = Task { @MainActor in
        let statsResponse = await Indicies.indexStats(serverDetails: detachedHost)
        guard !Task.isCancelled else { return }
        if statsResponse.httpStatus < 400, let parsedStats = statsResponse.parsed, !parsedStats.isEmpty {
          let parsedMap = Results.parseIndexStats(parsedStats)
          withAnimation(.easeInOut(duration: 0.2)) {
            self.indexStats = parsedMap
          }
        }
      }
      if sortOption == .recent {
        triggerFetchRecentActivity()
      }
    }
  }
}

struct macosManageIndexRowView: View {
  var indexName: String
  var stats: IndexStatsItem? = nil
  var activityTimestamp: Double? = nil
  var onSelect: (() -> Void)? = nil
  @State private var isHovered = false

  private var isHidden: Bool {
    indexName.hasPrefix(".")
  }

  private var tooltipText: String {
    var lines: [String] = [indexName]
    if isHidden {
      lines.append("(System / Hidden Index)")
    }

    var hasStats = false

    if let ts = activityTimestamp, ts.isFinite, ts > 0 {
      hasStats = true
      let fullDate = ManageIndexesSortHelper.formatFullActivity(timestamp: ts)
      let relDate = ManageIndexesSortHelper.formatRelativeActivity(timestamp: ts)
      lines.append("Activity: \(relDate) (\(fullDate))")
    }

    if let stats = stats {
      if let primaryDocs = stats.docCount, primaryDocs >= 0 {
        hasStats = true
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let priStr = formatter.string(from: NSNumber(value: primaryDocs)) ?? "\(primaryDocs)"
        if let totalDocs = stats.totalDocCount, totalDocs >= 0, totalDocs != primaryDocs {
          let totStr = formatter.string(from: NSNumber(value: totalDocs)) ?? "\(totalDocs)"
          lines.append("Documents: \(priStr) primary (\(totStr) total)")
        } else {
          lines.append("Documents: \(priStr)")
        }
        if let deleted = stats.deletedDocCount, deleted > 0 {
          let delStr = formatter.string(from: NSNumber(value: deleted)) ?? "\(deleted)"
          lines.append("Deleted Docs: \(delStr)")
        }
      }

      if let primaryBytes = stats.storageBytes, primaryBytes >= 0 {
        hasStats = true
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = [.useAll]
        byteFormatter.countStyle = .file
        byteFormatter.allowsNonnumericFormatting = false
        let priSizeStr = byteFormatter.string(fromByteCount: primaryBytes)
        if let totalBytes = stats.totalStorageBytes, totalBytes >= 0, totalBytes != primaryBytes {
          let totSizeStr = byteFormatter.string(fromByteCount: totalBytes)
          lines.append("Storage: \(priSizeStr) primary (\(totSizeStr) total)")
        } else {
          lines.append("Storage: \(priSizeStr)")
        }
      }
    }

    if !hasStats {
      lines.append("(Stats unavailable)")
    }

    lines.append("Click to view mapping and manage index")

    return lines.joined(separator: "\n")
  }

  var body: some View {
    Button(action: {
      onSelect?()
    }) {
      HStack(spacing: 8) {
        Image(systemName: isHidden ? "eye.slash" : "cylinder")
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary"))

        Text(indexName)
          .font(.system(size: 13, weight: .regular, design: .monospaced))
          .lineLimit(1)
          .truncationMode(.middle)

        if isHidden {
          Text("hidden")
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(Color("BackgroundFixedShadow"))
            .clipShape(Capsule())
            .foregroundColor(Color("TextSecondary"))
        }

        Spacer()

        HStack(spacing: 12) {
          if let ts = activityTimestamp, ts.isFinite, ts > 0 {
            HStack(spacing: 4) {
              Image(systemName: "clock")
                .font(.system(size: 10))
              Text(ManageIndexesSortHelper.formatRelativeActivity(timestamp: ts))
                .font(.system(size: 11, design: .monospaced))
            }
            .foregroundColor(Color("TextSecondary"))
          }

          if let stats = stats {
            if let docCountStr = stats.formattedDocCount {
              HStack(spacing: 4) {
                Image(systemName: "doc.text")
                  .font(.system(size: 10))
                Text(docCountStr)
                  .font(.system(size: 11, design: .monospaced))
              }
              .foregroundColor(Color("TextSecondary"))
            }

            if let storageStr = stats.formattedStorageSize {
              HStack(spacing: 4) {
                Image(systemName: "internaldrive")
                  .font(.system(size: 10))
                Text(storageStr)
                  .font(.system(size: 11, design: .monospaced))
              }
              .foregroundColor(Color("TextSecondary"))
            }
          }
        }
        .layoutPriority(1)

        Image(systemName: "chevron.right")
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(Color("TextSecondary"))
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(isHovered ? Color("ButtonHighlighted") : Color("Button"))
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .help(tooltipText)
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

struct macosManageIndexesSortButton: View {
  var option: ManageIndexesSortOption
  var isSelected: Bool
  var isAscending: Bool
  var isLoading: Bool
  var action: () -> Void

  @State private var isHovered: Bool = false

  private var tooltip: String {
    isSelected ? option.tooltip(isAscending: isAscending) : option.inactiveTooltip
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        if isLoading {
          ProgressView()
            .scaleEffect(0.5)
            .frame(width: 11, height: 11)
        } else {
          Image(systemName: option.iconName)
            .font(.system(size: 10, weight: .medium))
        }

        Text(option.rawValue)
          .font(.system(size: 11, weight: .medium))

        if isSelected {
          Image(systemName: isAscending ? "arrow.up" : "arrow.down")
            .font(.system(size: 8, weight: .bold))
        }
      }
      .fixedSize()
      .foregroundColor(isSelected ? .primary : Color("TextSecondary"))
      .padding(.horizontal, 7)
      .padding(.vertical, 4)
      .background(
        isSelected
          ? (isHovered ? Color("ButtonHighlighted") : Color("ButtonHighlighted").opacity(0.8))
          : (isHovered ? Color("ButtonHighlighted").opacity(0.4) : Color("Button"))
      )
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
    .help(tooltip)
    .accessibilityLabel(Text(option.rawValue))
    .accessibilityValue(Text(isSelected ? (isAscending ? "Ascending" : "Descending") : "Not selected"))
  }
}

#Preview {
  let host = HostDetails()
  host.name = "Production Cluster"
  return macosManageIndexesView(host: host, onBack: {})
    .frame(width: 400, height: 600)
    .padding()
}
#endif

// MARK: - Sort Models & Helpers

public enum ManageIndexesSortOption: String, CaseIterable, Identifiable, Sendable {
  case name = "Name"
  case recent = "Recent"
  case size = "Size"
  case docCount = "Doc Count"

  public var id: String { rawValue }

  public var iconName: String {
    switch self {
    case .name:
      return "textformat"
    case .recent:
      return "clock.arrow.circlepath"
    case .size:
      return "internaldrive"
    case .docCount:
      return "doc.text"
    }
  }

  public var defaultAscending: Bool {
    switch self {
    case .name:
      return true
    case .recent, .size, .docCount:
      return false
    }
  }

  public func tooltip(isAscending: Bool) -> String {
    switch self {
    case .name:
      return isAscending ? "Sorted by name (A to Z). Click to sort Z to A." : "Sorted by name (Z to A). Click to sort A to Z."
    case .recent:
      return isAscending ? "Sorted by recent activity (oldest first). Click to sort newest first." : "Sorted by recent activity (newest first). Click to sort oldest first."
    case .size:
      return isAscending ? "Sorted by storage size (smallest first). Click to sort largest first." : "Sorted by storage size (largest first). Click to sort smallest first."
    case .docCount:
      return isAscending ? "Sorted by document count (lowest first). Click to sort highest first." : "Sorted by document count (highest first). Click to sort lowest first."
    }
  }

  public var inactiveTooltip: String {
    switch self {
    case .name:
      return "Sort alphabetically by index name"
    case .recent:
      return "Sort by most recent document activity"
    case .size:
      return "Sort by storage size (largest first)"
    case .docCount:
      return "Sort by document count (highest first)"
    }
  }
}

public struct ManageIndexesSortHelper {
  private static let defaultRelativeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
  }()

  private static let defaultFullDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()

  public static func sortIndices(
    indices: [String],
    sortOption: ManageIndexesSortOption,
    ascending: Bool,
    stats: [String: IndexStatsItem] = [:],
    timestamps: [String: Double] = [:]
  ) -> [String] {
    var seen = Set<String>()
    let uniqueIndices = indices.filter { seen.insert($0).inserted }

    return uniqueIndices.sorted { a, b in
      switch sortOption {
      case .name:
        let comparison = a.localizedStandardCompare(b)
        if comparison != .orderedSame {
          return ascending ? (comparison == .orderedAscending) : (comparison == .orderedDescending)
        }
        return ascending ? (a < b) : (a > b)

      case .recent:
        let timeA = timestamps[a].flatMap { $0.isFinite && $0 > 0 && $0 < 1e14 ? $0 : nil }
        let timeB = timestamps[b].flatMap { $0.isFinite && $0 > 0 && $0 < 1e14 ? $0 : nil }
        switch (timeA, timeB) {
        case let (.some(tA), .some(tB)):
          if tA != tB {
            return ascending ? (tA < tB) : (tA > tB)
          }
          let comp = a.localizedStandardCompare(b)
          if comp != .orderedSame {
            return comp == .orderedAscending
          }
          return a < b
        case (.some, .none):
          return true
        case (.none, .some):
          return false
        case (.none, .none):
          let comp = a.localizedStandardCompare(b)
          if comp != .orderedSame {
            return comp == .orderedAscending
          }
          return a < b
        }

      case .size:
        let sizeA = stats[a]?.storageBytes.flatMap { $0 >= 0 ? $0 : nil }
        let sizeB = stats[b]?.storageBytes.flatMap { $0 >= 0 ? $0 : nil }
        switch (sizeA, sizeB) {
        case let (.some(sA), .some(sB)):
          if sA != sB {
            return ascending ? (sA < sB) : (sA > sB)
          }
          let comp = a.localizedStandardCompare(b)
          if comp != .orderedSame {
            return comp == .orderedAscending
          }
          return a < b
        case (.some, .none):
          return true
        case (.none, .some):
          return false
        case (.none, .none):
          let comp = a.localizedStandardCompare(b)
          if comp != .orderedSame {
            return comp == .orderedAscending
          }
          return a < b
        }

      case .docCount:
        let countA = stats[a]?.docCount.flatMap { $0 >= 0 ? $0 : nil }
        let countB = stats[b]?.docCount.flatMap { $0 >= 0 ? $0 : nil }
        switch (countA, countB) {
        case let (.some(cA), .some(cB)):
          if cA != cB {
            return ascending ? (cA < cB) : (cA > cB)
          }
          let comp = a.localizedStandardCompare(b)
          if comp != .orderedSame {
            return comp == .orderedAscending
          }
          return a < b
        case (.some, .none):
          return true
        case (.none, .some):
          return false
        case (.none, .none):
          let comp = a.localizedStandardCompare(b)
          if comp != .orderedSame {
            return comp == .orderedAscending
          }
          return a < b
        }
      }
    }
  }

  public static func formatRelativeActivity(timestamp: Double, relativeTo currentDate: Date = Date(), locale: Locale? = nil) -> String {
    guard timestamp.isFinite, timestamp > 0, timestamp < 1e14 else { return "Unknown" }
    let date = Date(timeIntervalSince1970: timestamp / 1000.0)
    if let locale = locale {
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .abbreviated
      formatter.locale = locale
      return formatter.localizedString(for: date, relativeTo: currentDate)
    }
    return defaultRelativeFormatter.localizedString(for: date, relativeTo: currentDate)
  }

  public static func formatFullActivity(timestamp: Double, locale: Locale? = nil) -> String {
    guard timestamp.isFinite, timestamp > 0, timestamp < 1e14 else { return "Unknown" }
    let date = Date(timeIntervalSince1970: timestamp / 1000.0)
    if let locale = locale {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .short
      formatter.locale = locale
      return formatter.string(from: date)
    }
    return defaultFullDateFormatter.string(from: date)
  }
}
