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

  var allCurrentIndices: [String] {
    showHiddenIndices ? (indexArray + hiddenIndexArray) : indexArray
  }

  var filteredIndices: [String] {
    IndexFilterHelper.filter(indices: allCurrentIndices, query: searchText)
      .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Top-left header with back button and index count
      HStack(spacing: 8) {
        Button(action: onBack) {
          Image(systemName: "chevron.left")
            .font(.system(size: 14, weight: .semibold))
            .padding(6)
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
                  stats: indexStats[indexName]
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
    }
  }

  @MainActor
  private func fetchIndices() async {
    statsTask?.cancel()
    statsTask = nil

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
    }
  }
}

struct macosManageIndexRowView: View {
  var indexName: String
  var stats: IndexStatsItem? = nil
  @State private var isHovered = false

  private var isHidden: Bool {
    indexName.hasPrefix(".")
  }

  private var tooltipText: String {
    var lines: [String] = [indexName]
    if isHidden {
      lines.append("(System / Hidden Index)")
    }
    guard let stats = stats else {
      lines.append("(Stats unavailable)")
      return lines.joined(separator: "\n")
    }

    var hasStats = false

    if let primaryDocs = stats.docCount {
      hasStats = true
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      let priStr = formatter.string(from: NSNumber(value: primaryDocs)) ?? "\(primaryDocs)"
      if let totalDocs = stats.totalDocCount, totalDocs != primaryDocs {
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

    if let primaryBytes = stats.storageBytes {
      hasStats = true
      let byteFormatter = ByteCountFormatter()
      byteFormatter.allowedUnits = [.useAll]
      byteFormatter.countStyle = .file
      byteFormatter.allowsNonnumericFormatting = false
      let priSizeStr = byteFormatter.string(fromByteCount: primaryBytes)
      if let totalBytes = stats.totalStorageBytes, totalBytes != primaryBytes {
        let totSizeStr = byteFormatter.string(fromByteCount: totalBytes)
        lines.append("Storage: \(priSizeStr) primary (\(totSizeStr) total)")
      } else {
        lines.append("Storage: \(priSizeStr)")
      }
    }

    if !hasStats {
      lines.append("(Stats unavailable)")
    }

    return lines.joined(separator: "\n")
  }

  var body: some View {
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

      if let stats = stats {
        HStack(spacing: 12) {
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
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(isHovered ? Color("ButtonHighlighted") : Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .contentShape(Rectangle())
    .help(tooltipText)
    .onHover { hovering in
      isHovered = hovering
    }
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
