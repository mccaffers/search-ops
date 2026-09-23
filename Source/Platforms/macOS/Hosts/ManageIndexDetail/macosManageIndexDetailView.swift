// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(macOS)

public enum IndexDetailTab: String, CaseIterable {
  case mapping = "Mapping"
  case manage = "Manage"
}

public struct macosManageIndexDetailView: View {
  public var host: HostDetails
  public var indexName: String
  public var initialStats: IndexStatsItem? = nil
  public var onBack: () -> Void

  @State private var selectedTab: IndexDetailTab = .mapping
  @State private var stats: IndexStatsItem? = nil
  @State private var mappingFields: [SquashedFieldsArray] = []
  @State private var dateFields: [DateFieldInfo] = []
  @State private var rawMappingJson: String = ""
  @State private var isLoading: Bool = true
  @State private var errorMessage: String? = nil
  @State private var isBackHovered: Bool = false
  @State private var isRefreshHovered: Bool = false
  @State private var loadTask: Task<Void, Never>? = nil

  public init(
    host: HostDetails,
    indexName: String,
    initialStats: IndexStatsItem? = nil,
    onBack: @escaping () -> Void
  ) {
    self.host = host
    self.indexName = indexName
    self.initialStats = initialStats
    self.onBack = onBack
  }

  private var isHidden: Bool {
    indexName.hasPrefix(".")
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      headerView

      tabBarView

      if isLoading {
        RepeatedPlaceholderView()
        Spacer()
      } else if let error = errorMessage {
        errorView(message: error)
        Spacer()
      } else {
        switch selectedTab {
        case .mapping:
          macosIndexMappingTabView(fields: mappingFields, rawJson: rawMappingJson)
        case .manage:
          macosIndexManageOperationsTabView(
            host: host,
            indexName: indexName,
            dateFields: dateFields,
            currentDocCount: stats?.docCount,
            onStatsUpdated: {
              Task {
                await reloadStats()
              }
            }
          )
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .onAppear {
      self.stats = initialStats
      startLoading()
    }
    .onDisappear {
      loadTask?.cancel()
      loadTask = nil
    }
  }

  // MARK: - Header View

  @ViewBuilder
  private var headerView: some View {
    HStack(spacing: 8) {
      Button(action: onBack) {
        Image(systemName: "chevron.left")
          .font(.system(size: 20, weight: .semibold))
          .padding(8)
          .background(isBackHovered ? Color("ButtonHighlighted") : Color.clear)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .onHover { hovering in
        isBackHovered = hovering
      }
      .help("Back to indexes list")

      Image(systemName: isHidden ? "eye.slash" : "cylinder")
        .font(.system(size: 16))
        .foregroundColor(Color("TextSecondary"))

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(indexName)
            .font(.system(size: 18, weight: .semibold, design: .monospaced))
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
        }

        if !host.isInvalidated {
          Text(host.name)
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
        }
      }

      Spacer()

      // Metadata Stats Badges
      HStack(spacing: 8) {
        if let stats = stats {
          if let docCountStr = stats.formattedDocCount {
            HStack(spacing: 4) {
              Image(systemName: "doc.text")
                .font(.system(size: 11))
              Text(docCountStr)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("Button"))
            .clipShape(Capsule())
            .foregroundColor(Color("TextSecondary"))
          }

          if let storageStr = stats.formattedStorageSize {
            HStack(spacing: 4) {
              Image(systemName: "internaldrive")
                .font(.system(size: 11))
              Text(storageStr)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("Button"))
            .clipShape(Capsule())
            .foregroundColor(Color("TextSecondary"))
          }
        }

        Button(action: {
          startLoading()
        }) {
          Image(systemName: "arrow.clockwise")
            .font(.system(size: 13, weight: .medium))
            .padding(6)
            .background(isRefreshHovered ? Color("ButtonHighlighted") : Color("Button"))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isRefreshHovered = hovering
        }
        .help("Refresh mapping and stats")
      }
    }
    .padding(.top, 10)
    .padding(.bottom, 4)
  }

  // MARK: - Tab Bar View

  @ViewBuilder
  private var tabBarView: some View {
    HStack(spacing: 8) {
      tabButton(
        title: "Mapping",
        icon: "doc.text.magnifyingglass",
        tab: .mapping
      )

      tabButton(
        title: "Manage",
        icon: "slider.horizontal.3",
        tab: .manage
      )

      Spacer()
    }
    .padding(.bottom, 6)
  }

  @ViewBuilder
  private func tabButton(title: String, icon: String, tab: IndexDetailTab) -> some View {
    let isSelected = selectedTab == tab
    Button(action: {
      selectedTab = tab
    }) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
        Text(title)
          .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(isSelected ? Color("ButtonHighlighted") : Color("Button"))
      .foregroundColor(isSelected ? .primary : Color("TextSecondary"))
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
  }

  // MARK: - Error View

  @ViewBuilder
  private func errorView(message: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(.orange)
        Text("Unable to Load Index Details")
          .font(.headline)
      }
      Text(message)
        .font(.subheadline)
        .foregroundColor(Color("TextSecondary"))

      Button(action: {
        startLoading()
      }) {
        HStack(spacing: 4) {
          Image(systemName: "arrow.clockwise")
          Text("Retry")
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
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("BackgroundFixedShadow"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }

  // MARK: - Data Loading

  private func startLoading() {
    isLoading = true
    errorMessage = nil

    loadTask?.cancel()
    let detachedHost = host.generateCopy()
    loadTask = Task {
      async let mappingResult = IndexManagementService.fetchIndexMapping(serverDetails: detachedHost, index: indexName)
      async let statsResult = Indicies.indexStats(serverDetails: detachedHost, index: indexName)

      let mapping = await mappingResult
      let statsResponse = await statsResult

      guard !Task.isCancelled else { return }

      await MainActor.run {
        if let err = mapping.error {
          self.errorMessage = err.message
          self.isLoading = false
          return
        }

        self.mappingFields = mapping.fields
        self.dateFields = mapping.dateFields
        self.rawMappingJson = mapping.rawJson

        if let data = statsResponse.data,
           let statsString = String(data: data, encoding: .utf8) {
          let parsedStats = Results.parseIndexStats(statsString)
          if let item = IndexManagementService.extractIndexStats(from: parsedStats, for: indexName) {
            self.stats = item
          }
        }

        self.isLoading = false
      }
    }
  }

  private func reloadStats() async {
    let detachedHost = host.generateCopy()
    let statsResponse = await Indicies.indexStats(serverDetails: detachedHost, index: indexName)
    guard let data = statsResponse.data,
          let statsString = String(data: data, encoding: .utf8) else {
      return
    }

    let parsedStats = Results.parseIndexStats(statsString)
    if let item = IndexManagementService.extractIndexStats(from: parsedStats, for: indexName) {
      await MainActor.run {
        self.stats = item
      }
    }
  }
}
#endif
