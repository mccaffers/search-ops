// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import OrderedCollections

#if os(iOS)

/// Loading a saved document from its host
enum iosSavedDocumentLoadState: Equatable {
  case loading
  case loaded
  /// Found in another index than the one it was saved from. `saved` when the new index was saved with it.
  case moved(from: String, to: String, saved: Bool)
  /// Not in any of the indices or patterns searched
  case notFound(searched: [String])
  case failed(String)
}

/// A saved document, fetched again from its host each time it's opened. Each value can be searched for in the
/// Search tab, over the search the document was saved from.
struct iosSavedDocumentView: View {
  /// As saved, which may change when the document is found to have moved
  @State var document: SavedDocument
  var onSearch: (SearchHandoffRequest) -> Void
  /// Called after the document is renamed, moved or removed, for the list to reload
  var onChanged: () -> Void

  @EnvironmentObject var serverObjects: HostsDataManager
  @Environment(\.dismiss) private var dismiss

  @State private var loadState: iosSavedDocumentLoadState = .loading
  @State private var row: OrderedDictionary<String, Any>? = nil
  @State private var fieldTypes: [String: String] = [:]
  @State private var showingJSON = false
  @State private var loadTask: Task<Void, Never>? = nil

  private let manager = SavedDocumentDataManager()

  private var host: HostDetails? {
    guard let host = serverObjects.getHostByID(document.hostId), !host.isInvalidated else { return nil }
    return host
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      status

      if let row = row {
        if showingJSON {
          DetailJSONViewer(contents: json(row).prettifyJSON())
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(DocumentDetail.filteredKeys(row, matching: ""), id: \.self) { key in
                if let value = row[key].flatMap(DocumentDetail.formatDisplayValue) {
                  fieldCard(key: key, value: value)
                }
              }
            }
            .padding(.top, 10)
          }
        }
      } else if loadState == .loading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color("Background"))
    .navigationTitle(document.displayTitle)
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackgroundVisibleBeforeiOS26()
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          unsave()
        } label: {
          Image(systemName: "bookmark.fill")
        }
        .tint(Color("AccentColor"))
        .accessibilityLabel("Remove from Saved")
      }
      if row != nil {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(showingJSON ? "Document" : "JSON") {
            showingJSON.toggle()
          }
          .tint(Color("AccentColor"))
        }
      }
    }
    .onAppear {
      if row == nil {
        load()
      }
    }
    .onDisappear {
      loadTask?.cancel()
    }
  }

  @ViewBuilder
  private var status: some View {
    switch loadState {
    case .notFound(let searched):
      statusText("Not found in \(searched.joined(separator: " or ")). It may have been deleted.", warning: true)
    case .moved(let from, let to, let saved):
      // Not saved when other indices have a document with the same id, and the newest was opened
      statusText(saved ? "Moved from \(from) to \(to)." : "Not in \(from), opened the newest copy in \(to).",
                 warning: false)
    case .failed(let reason):
      statusText(reason, warning: true)
    case .loading, .loaded:
      EmptyView()
    }
  }

  private func statusText(_ text: String, warning: Bool) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Image(systemName: warning ? "exclamationmark.triangle" : "info.circle")
        .foregroundColor(warning ? .orange : Color("TextSecondary"))
      Text(text)
        .foregroundColor(Color("TextColor"))
    }
      .font(.subheadline)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color("Button"))
      .cornerRadius(5)
      .padding(.horizontal, 15)
      .padding(.top, 10)
  }

  private func fieldCard(key: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .bottom, spacing: 2) {
        Text(key)
          .font(.system(size: 18))
          .foregroundColor(Color("LabelBackgroundFocus"))
        if let type = fieldTypes[key] {
          Text(type)
            .font(.system(size: 15))
            .padding(.horizontal, 5)
            .foregroundColor(Color("TextSecondary"))
            .padding(.bottom, 2)
        }
      }
      .padding(.horizontal, 18)

      HStack {
        Text(value.trimmingCharacters(in: .whitespacesAndNewlines))
          .font(.system(size: 16))
          .foregroundColor(Color("TextColor"))
          .textSelection(.enabled)
          .padding(.vertical, 15)

        Spacer()

        Menu {
          Button {
            search(field: key, value: value, negated: false)
          } label: {
            Label("Search for This Value", systemImage: "magnifyingglass")
          }
          Button {
            search(field: key, value: value, negated: true)
          } label: {
            Label("Search Without This Value", systemImage: "minus.magnifyingglass")
          }
          Button {
            UIPasteboard.general.string = value
          } label: {
            Label("Copy Value", systemImage: "doc.on.doc")
          }
        } label: {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 18))
            .padding(.vertical, 8)
            .padding(.horizontal, 5)
            .foregroundColor(Color("TextSecondary"))
        }
        .accessibilityLabel("Search \(key)")
      }
      .padding(.horizontal, 15)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color("BackgroundAlt"))
      .cornerRadius(5)
      .padding(.horizontal, 15)
      .padding(.bottom, 10)
    }
  }

  private func json(_ row: OrderedDictionary<String, Any>) -> String {
    let detail = DocumentDetail()
    detail.item = row
    return detail.asJson()
  }

  // MARK: - Actions

  /// Fetches the document from the cluster
  private func load() {
    loadTask?.cancel()
    guard let host = host else {
      loadState = .failed("The host this document was saved from no longer exists.")
      return
    }
    loadState = .loading
    let hostCopy = host.generateCopy()
    let opened = document
    loadTask = Task {
      let result = await SavedDocumentSearch.load(opened, host: hostCopy, dataView: nil)
      guard !Task.isCancelled else { return }
      switch result {
      case .found(let content):
        // The mapping gives each field its type, as in Search. It's the index the document was found in, which
        // isn't the saved one when it's moved.
        let mapping = await IndexMap.indexMappings(serverDetails: hostCopy, index: content.ref.index)
        guard !Task.isCancelled else { return }
        fieldTypes = Dictionary(mapping.map { ($0.squashedString, $0.type) }, uniquingKeysWith: { first, _ in first })
        row = content.row
        if let move = content.move {
          loadState = .moved(from: move.from, to: content.ref.index,
                             saved: move.isCertain && relocate(to: content.ref.index))
        } else {
          loadState = .loaded
        }
      case .notFound:
        let fallback = SavedDocumentSearch.fallbackIndex(for: opened, dataView: nil)
        loadState = .notFound(searched: [opened.docIndex] + (fallback.map { [$0] } ?? []))
      case .failed(let error):
        loadState = .failed(error.message)
      }
    }
  }

  /// Saves the index the document was found in, so it's opened from there next time
  private func relocate(to index: String) -> Bool {
    guard let relocated = manager.relocate(id: document.id, to: index) else { return false }
    document = relocated
    onChanged()
    return true
  }

  /// Searches the Search tab for documents with, or without, one of the document's values
  private func search(field: String, value: String, negated: Bool) {
    guard host != nil else {
      loadState = .failed("The host this document was saved from no longer exists.")
      return
    }
    onSearch(SavedDocumentSearch.termQuerySearch(for: document, field: field, value: value, negated: negated,
                                                 dataView: nil))
  }

  private func unsave() {
    manager.delete(id: document.id)
    onChanged()
    dismiss()
  }
}
#endif
