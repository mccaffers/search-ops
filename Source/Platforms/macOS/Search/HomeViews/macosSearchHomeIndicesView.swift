// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftUI

#if os(macOS)
struct macosSearchHomeIndicesView: View {
  
  @Binding var localSelectedHost: HostDetails?
  @Binding var localSelectedIndex : String
  @Binding var indexArray : [String]
  
  @Binding var selectedHost: HostDetails?
  @Binding var selectedIndex: String
  @Binding var fields : [SquashedFieldsArray]
  
  @Binding var loadingIndices : Bool
  @Binding var indexError: ResponseError?
  
  @ObservedObject var localFilterObject: FilterObject
  
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  var mappingsRequest : () async -> ()
  var updateIndexArray : () async -> ()
  
  @State var hoveringActiveButton = false
  @State private var indexFilterText: String = ""
  @State private var isSortedByRecentActivity: Bool = false
  @State private var isLoadingRecentActivity: Bool = false
  @State private var cachedTimestamps: [String: Double] = [:]
  @State private var recentSortedIndices: [String] = []
  @State private var activeSortTask: Task<Void, Never>? = nil
  @State private var sortStatusMessage: String? = nil
  
  var trimmedFilter: String {
    indexFilterText.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  var filteredIndices: [String] {
    let source = isSortedByRecentActivity ? recentSortedIndices : indexArray
    return IndexFilterHelper.filter(
      indices: source,
      query: indexFilterText,
      preserveOrder: isSortedByRecentActivity
    )
  }
  
  var showAllButton: Bool {
    guard !isSortedByRecentActivity else { return false }
    return IndexFilterHelper.showAllButton(query: indexFilterText)
  }
  
  var body: some View {
    
    VStack (alignment:.leading, spacing:5){
      
      HStack {
        if !trimmedFilter.isEmpty && localSelectedIndex.isEmpty {
          let count = filteredIndices.count + (showAllButton ? 1 : 0)
          let total = IndexFilterHelper.totalCount(indices: indexArray, includeAll: showAllButton)
          Text("Indices (\(count) of \(total))")
            .font(.subheadline)
            .foregroundStyle(Color("TextSecondary"))
        } else {
          Text("Indices")
            .font(.subheadline)
            .foregroundStyle(Color("TextSecondary"))
        }
        Spacer()
      }
      
      if indexError != nil {
        HStack {
          HStack {
            Image(systemName: "exclamationmark.triangle")
              .foregroundStyle(.red)
              .font(.system(size: 20))
            VStack(alignment: .leading, spacing:3) {
              Text(indexError?.title ?? "Error")
              Text(indexError?.message ?? "")
            }
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 15)
          .background(Color("BackgroundAlt"))
          .clipShape(.rect(cornerRadius: 5))
          Button {
            Task {
              await updateIndexArray()
            }
          } label: {
            VStack(spacing:5) {
              Image(systemName: "arrow.triangle.2.circlepath")
              Text("Retry")
            }
            .padding(10)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
          }.buttonStyle(PlainButtonStyle())

        }
      } else if loadingIndices {
        HStack {
          ProgressView()
            .scaleEffect(0.7)
            .padding(.vertical, 2)
            .padding(.horizontal, 5)
          Text("Loading indices")
            .font(.subheadline)
          
        }
      } else if !localSelectedIndex.isEmpty {
        HStack {
          Button(action: {
            withAnimation {
              localSelectedIndex = ""
              indexFilterText = ""
              localFilterObject.clear()
              fields = []
            }
          }) {
            Text(localSelectedIndex)
              .padding(10)
              .background(Color("Background"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .onHover { hover in
            hoveringActiveButton = hover
          }
          if hoveringActiveButton {
            Image(systemName: "xmark.circle")
              .bold()
              .padding(.leading, -15)
              .padding(.top, -25)
          }
        }
      } else {
        if !indexArray.isEmpty {
          HStack(spacing: 8) {
            HStack(spacing: 6) {
              Image(systemName: "magnifyingglass")
                .foregroundColor(Color("TextSecondary"))
                .font(.system(size: 11))
              
              TextField("Filter indices...", text: $indexFilterText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 13))
                .disableAutocorrection(true)
#if os(macOS)
                .onExitCommand {
                  indexFilterText = ""
                }
#endif
              
              if !indexFilterText.isEmpty {
                Button(action: {
                  indexFilterText = ""
                }) {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color("TextSecondary"))
                    .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Clear filter")
              }
            }
            .padding(.horizontal, 8)
            .frame(height: 32)
            .frame(maxWidth: 320)
            .background(Color("Button"))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
              RoundedRectangle(cornerRadius: 5)
                .stroke(Color("BackgroundAlt"), lineWidth: 1)
            )
            
            Button(action: {
              handleRecentActivityToggle()
            }) {
              HStack(spacing: 6) {
                if isLoadingRecentActivity {
                  ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 14, height: 14)
                } else {
                  Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11))
                }
                Text("Recent Activity")
                  .font(.system(size: 12))
              }
              .padding(.horizontal, 10)
              .frame(height: 32)
              .background(isSortedByRecentActivity ? Color("ButtonHighlighted") : Color("Button"))
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color("BackgroundAlt"), lineWidth: 1)
              )
            }
            .buttonStyle(PlainButtonStyle())
            .help(isSortedByRecentActivity ? "Click to revert to alphabetical sort (currently sorted by recent activity using /_mapping across all indices to find the date)" : "Sort indices by most recent document activity using /_mapping across all indices to find the date")
            
            if let message = sortStatusMessage {
              Text(message)
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
            }
            
            Spacer()
          }
          .padding(.bottom, 4)
        }
        
        if !showAllButton && filteredIndices.isEmpty {
          HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(Color("TextSecondary"))
            Text("No indices matching \"\(trimmedFilter)\"")
              .foregroundColor(Color("TextSecondary"))
              .font(.subheadline)
          }
          .padding(.vertical, 8)
        } else {
          WrappingHStack(horizontalSpacing: 5) {
            if showAllButton {
              Button(action: {
                indexFilterText = ""
                localFilterObject.resetIndexSpecificFilters()
                withAnimation {
                  localSelectedIndex = "_all"
                }
              }) {
                Text("_all")
                  .padding(10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }.buttonStyle(PlainButtonStyle())
            }
            
            
            // TODO #2 we need to limit the filtered indices to say 30? something sensible, and if filtered display a [Too many to show]
            ForEach(IndexFilterHelper.limitIndices(filteredIndices), id: \.self) { indexName in
              Button(action: {
                indexFilterText = ""
                localFilterObject.resetIndexSpecificFilters()
                withAnimation {
                  localSelectedIndex = indexName
                }
                
                Task {
                  // mappings request
                  await mappingsRequest()
                }
              }) {
                Text(indexName)
                  .padding(10)
                  .background(localSelectedIndex == indexName ? Color("ButtonHighlighted") : Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }.buttonStyle(PlainButtonStyle())
            }
            
            if IndexFilterHelper.hasExceededLimit(filteredIndices) {
              Text("[Too many to show]")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .padding(10)
                .background(Color("BackgroundAlt"))
                .clipShape(.rect(cornerRadius: 5))
                .help("Showing first \(IndexFilterHelper.defaultDisplayLimit) of \(filteredIndices.count) indices. Type in the filter box to narrow results.")
            }
          }
        }
      }
    }
    .onChange(of: localSelectedHost?.id) { _ in
      resetRecentActivityState()
    }
    .onChange(of: indexArray) { _ in
      resetRecentActivityState()
    }
    .onDisappear {
      activeSortTask?.cancel()
      activeSortTask = nil
      isLoadingRecentActivity = false
    }
  }
  
  private func handleRecentActivityToggle() {
    if isLoadingRecentActivity {
      activeSortTask?.cancel()
      activeSortTask = nil
      isLoadingRecentActivity = false
      isSortedByRecentActivity = false
      return
    }
    
    if isSortedByRecentActivity {
      isSortedByRecentActivity = false
      sortStatusMessage = nil
      return
    }
    
    if !cachedTimestamps.isEmpty {
      recentSortedIndices = IndexActivityService.sortIndicesByActivity(
        indices: indexArray,
        timestamps: cachedTimestamps
      )
      isSortedByRecentActivity = true
      sortStatusMessage = nil
      return
    }
    
    guard let host = localSelectedHost ?? selectedHost else { return }
    
    isLoadingRecentActivity = true
    sortStatusMessage = nil
    
    activeSortTask = Task {
      let result = await IndexActivityService.fetchIndicesActivity(
        serverDetails: host,
        indices: indexArray
      )
      
      guard !Task.isCancelled else { return }
      
      isLoadingRecentActivity = false
      activeSortTask = nil
      
      if let errorMsg = result.errorMessage {
        sortStatusMessage = errorMsg
        isSortedByRecentActivity = false
        return
      }
      
      cachedTimestamps = result.timestamps
      recentSortedIndices = result.sortedIndices
      isSortedByRecentActivity = true
      sortStatusMessage = nil
    }
  }
  
  private func resetRecentActivityState() {
    activeSortTask?.cancel()
    activeSortTask = nil
    isLoadingRecentActivity = false
    isSortedByRecentActivity = false
    cachedTimestamps = [:]
    recentSortedIndices = []
    sortStatusMessage = nil
    indexFilterText = ""
  }
}
#endif

public struct IndexFilterHelper {
  public static let defaultDisplayLimit: Int = 30
  
  public static func matches(indexName: String, query: String) -> Bool {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return true }
    if trimmed.contains("*") || trimmed.contains("?") {
      var sanitized = trimmed
      while sanitized.contains("**") {
        sanitized = sanitized.replacingOccurrences(of: "**", with: "*")
      }
      let pattern = "^" + NSRegularExpression.escapedPattern(for: sanitized)
        .replacingOccurrences(of: "\\*", with: ".*")
        .replacingOccurrences(of: "\\?", with: ".") + "$"
      if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
        let range = NSRange(location: 0, length: indexName.utf16.count)
        return regex.firstMatch(in: indexName, options: [], range: range) != nil
      }
    }
    return indexName.localizedCaseInsensitiveContains(trimmed)
  }
  
  public static func filter(indices: [String], query: String, preserveOrder: Bool = false) -> [String] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let base: [String]
    if preserveOrder {
      var seen = Set<String>()
      base = indices.filter { $0 != "_all" && seen.insert($0).inserted }
    } else {
      base = Array(Set(indices.filter { $0 != "_all" })).sorted(by: <)
    }
    guard !trimmed.isEmpty else {
      return base
    }
    return base.filter { matches(indexName: $0, query: trimmed) }
  }
  
  public static func limitIndices(_ indices: [String], limit: Int = defaultDisplayLimit) -> [String] {
    return Array(indices.prefix(limit))
  }
  
  public static func hasExceededLimit(_ indices: [String], limit: Int = defaultDisplayLimit) -> Bool {
    return indices.count > limit
  }
  
  public static func showAllButton(query: String) -> Bool {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return true }
    return matches(indexName: "_all", query: trimmed)
  }
  
  public static func totalCount(indices: [String], includeAll: Bool = true) -> Int {
    let uniqueIndices = Set(indices.filter { $0 != "_all" })
    return uniqueIndices.count + (includeAll ? 1 : 0)
  }
}

