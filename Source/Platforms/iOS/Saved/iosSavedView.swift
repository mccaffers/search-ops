// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)

/// Hands a search from the Saved tab to the Search tab, which runs it when it hears about it
@MainActor
final class iosSearchHandoff: ObservableObject {
  /// New for each search sent, for the Search tab to watch
  @Published private(set) var pendingId: UUID? = nil
  private var pending: SearchHandoffRequest? = nil

  func send(_ request: SearchHandoffRequest) {
    pending = request
    pendingId = UUID()
  }

  /// The search waiting to run, once. Later calls get nil until another is sent.
  func take() -> SearchHandoffRequest? {
    defer { pending = nil }
    return pending
  }
}

/// A saved document or search, for renaming and removing either
enum iosSavedItem: Identifiable {
  case document(SavedDocument)
  case search(SavedSearch)

  var id: UUID {
    switch self {
    case .document(let document): return document.id
    case .search(let search): return search.id
    }
  }

  var title: String {
    switch self {
    case .document(let document): return document.title
    case .search(let search): return search.title
    }
  }

  var displayTitle: String {
    switch self {
    case .document(let document): return document.displayTitle
    case .search(let search): return search.displayTitle
    }
  }

  /// Shown when the title is left empty
  var defaultTitle: String {
    switch self {
    case .document(let document):
      return SavedDocument.defaultTitle(for: document.ref)
    case .search(let search):
      return SavedSearch.defaultTitle(query: search.query, index: search.searchIndex, filterCount: search.fieldFilters.count)
    }
  }
}

struct iosSavedView: View {
  /// Runs a saved search, or a search for one of a saved document's values, in the Search tab
  var onSearch: (SearchHandoffRequest) -> Void

  @EnvironmentObject var serverObjects: HostsDataManager

  @State private var documents: [SavedDocument] = []
  @State private var searches: [SavedSearch] = []
  @State private var message: String? = nil
  @State private var path = NavigationPath()

  @State private var pendingRename: iosSavedItem? = nil
  @State private var renameText = ""
  @State private var pendingDelete: iosSavedItem? = nil
  @State private var confirmingClear = false
  /// Remembered between visits, as it's a way of looking at the tab rather than part of what's saved
  @AppStorage("iosSavedItemFilter") private var filterRaw: String = SavedItemFilter.all.rawValue

  var filter: SavedItemFilter {
    SavedItemFilter(rawValue: filterRaw) ?? .all
  }

  private let manager = SavedDocumentDataManager()
  private let searchManager = SavedSearchDataManager()

  /// Every saved item, whatever the switch shows
  var allGroups: [SavedDocumentGroup] {
    let hosts = serverObjects.items.filter { !$0.isInvalidated }.map { (id: $0.id, name: $0.name) }
    return SavedDocument.grouped(documents, searches: searches, hosts: hosts)
  }

  /// The items the switch shows
  var groups: [SavedDocumentGroup] {
    filter.apply(allGroups)
  }

  var body: some View {
    NavigationStack(path: $path) {
      VStack(alignment: .leading, spacing: 0) {
        if allGroups.isEmpty {
          emptyState
        } else {
          SwiftUI.Picker("Show", selection: $filterRaw) {
            ForEach(SavedItemFilter.allCases, id: \.self) { option in
              Text(option.title).tag(option.rawValue)
            }
          }
          .pickerStyle(.segmented)
          // Otherwise it takes the height the list leaves over
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 15)
          .padding(.top, 5)
          .padding(.bottom, 5)

          if let message = message {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
              Text(message)
                .foregroundColor(Color("TextColor"))
            }
              .font(.subheadline)
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Color("Button"))
              .cornerRadius(5)
              .padding(.horizontal, 15)
              .padding(.top, 5)
          }

          if groups.isEmpty {
            Text(filter == .searches ? "No saved searches" : "No saved documents")
              .font(.subheadline)
              .foregroundColor(Color("TextSecondary"))
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else {
            list
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(Color("Background"))
      .navigationTitle("Saved")
      .navigationBarTitleDisplayMode(.large)
      .navigationBarBackgroundVisibleBeforeiOS26()
      .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
      .toolbar {
        if !groups.isEmpty {
          ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
              Button(role: .destructive) {
                confirmingClear = true
              } label: {
                Label(Self.clearTitle(filter), systemImage: "trash")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More")
          }
        }
      }
      .navigationDestination(for: SavedDocument.self) { document in
        iosSavedDocumentView(document: document,
                             onSearch: onSearch,
                             onChanged: reload)
      }
    }
    .onAppear {
      serverObjects.refresh()
      // Safety net for saved items left behind by a host deleted elsewhere. Only once the hosts have loaded, so a
      // database that failed to open doesn't look like every host was deleted.
      let hostIds = Set(serverObjects.items.filter { !$0.isInvalidated }.map(\.id))
      if !hostIds.isEmpty {
        manager.pruneOrphans(validHostIds: hostIds)
        searchManager.pruneOrphans(validHostIds: hostIds)
      }
      reload()
    }
    .alert(
      "Rename",
      isPresented: Binding(
        get: { pendingRename != nil },
        set: { if !$0 { pendingRename = nil } }
      ),
      presenting: pendingRename
    ) { item in
      TextField(item.defaultTitle, text: $renameText)
      Button("Cancel", role: .cancel) { }
      Button("Rename") {
        rename(item, to: renameText)
      }
    } message: { item in
      switch item {
      case .document:
        Text("Leave it empty to show the document's index and id.")
      case .search:
        Text("Leave it empty to show a summary of the search.")
      }
    }
    .alert("\(Self.clearTitle(filter))?", isPresented: $confirmingClear) {
      Button("Cancel", role: .cancel) { }
      Button(Self.clearTitle(filter), role: .destructive) {
        clear(filter)
      }
    } message: {
      Text(Self.clearMessage(filter, count: groups.reduce(0) { $0 + $1.count }))
    }
    .alert(
      "Remove from Saved?",
      isPresented: Binding(
        get: { pendingDelete != nil },
        set: { if !$0 { pendingDelete = nil } }
      ),
      presenting: pendingDelete
    ) { item in
      Button("Cancel", role: .cancel) { }
      Button("Remove", role: .destructive) {
        remove(item)
      }
    } message: { item in
      switch item {
      case .document:
        Text("\"\(item.displayTitle)\" will be removed from Saved. The document on the cluster isn't affected.")
      case .search:
        Text("\"\(item.displayTitle)\" will be removed from Saved.")
      }
    }
  }

  private var list: some View {
    List {
      ForEach(groups) { group in
        Section {
          ForEach(group.searches) { search in
            iosSavedSearchRowView(search: search) {
              run(search)
            }
            .contextMenu {
              Button {
                run(search)
              } label: {
                Label("Run Search", systemImage: "magnifyingglass")
              }
              renameButton(.search(search))
              Divider()
              removeButton(.search(search))
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              removeButton(.search(search))
              renameButton(.search(search))
                .tint(Color("ButtonHighlighted"))
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 15, bottom: 4, trailing: 15))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          }

          ForEach(group.documents) { document in
            // A button rather than a link, which would add a second chevron outside the card
            Button {
              path.append(document)
            } label: {
              iosSavedDocumentRowView(document: document)
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
              Button {
                path.append(document)
              } label: {
                Label("Open", systemImage: "doc.text")
              }
              renameButton(.document(document))
              Button {
                UIPasteboard.general.string = document.docId
              } label: {
                Label("Copy Document ID", systemImage: "doc.on.doc")
              }
              Divider()
              removeButton(.document(document))
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              removeButton(.document(document))
              renameButton(.document(document))
                .tint(Color("ButtonHighlighted"))
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 15, bottom: 4, trailing: 15))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          }
        } header: {
          Text(group.hostName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color("TextSecondary"))
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  private func renameButton(_ item: iosSavedItem) -> some View {
    Button {
      renameText = item.title
      pendingRename = item
    } label: {
      Label("Rename", systemImage: "pencil")
    }
  }

  private func removeButton(_ item: iosSavedItem) -> some View {
    Button(role: .destructive) {
      pendingDelete = item
    } label: {
      Label("Remove", systemImage: "trash")
    }
  }

  private var emptyState: some View {
    VStack(spacing: 8) {
      Image(systemName: "bookmark")
        .font(.system(size: 28))
        .foregroundColor(Color("TextSecondary"))
      Text("Nothing saved yet")
        .font(.headline)
      Text("Tap Save in Search to keep a search's query, time period, sort and fields here, or tap the bookmark on a document to keep that document. Saved items stay on this device.")
        .font(.subheadline)
        .foregroundColor(Color("TextSecondary"))
        .multilineTextAlignment(.center)
        .frame(maxWidth: 380)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  // MARK: - Actions

  private func reload() {
    documents = manager.all()
    searches = searchManager.all()
  }

  /// Runs a saved search in the Search tab
  private func run(_ search: SavedSearch) {
    guard let host = serverObjects.getHostByID(search.hostId), !host.isInvalidated else {
      message = "The host this search was saved from no longer exists."
      return
    }
    message = nil
    onSearch(search.request(dataView: nil))
  }

  static func clearTitle(_ filter: SavedItemFilter) -> String {
    switch filter {
    case .all: return "Clear All"
    case .documents: return "Clear Documents"
    case .searches: return "Clear Searches"
    }
  }

  /// eg. "All 3 saved items will be removed from this device. Documents on the cluster aren't affected."
  static func clearMessage(_ filter: SavedItemFilter, count: Int) -> String {
    let noun: String
    switch filter {
    case .all: noun = count == 1 ? "saved item" : "saved items"
    case .documents: noun = count == 1 ? "saved document" : "saved documents"
    case .searches: noun = count == 1 ? "saved search" : "saved searches"
    }
    let items = count == 1 ? "The \(noun)" : "All \(count) \(noun)"
    let cluster = filter == .searches ? "" : " Documents on the cluster aren't affected."
    return "\(items) will be removed from this device.\(cluster)"
  }

  /// Removes the kind of saved item the switch shows
  private func clear(_ filter: SavedItemFilter) {
    if filter != .searches {
      manager.deleteAll()
    }
    if filter != .documents {
      searchManager.deleteAll()
    }
    reload()
  }

  private func rename(_ item: iosSavedItem, to title: String) {
    switch item {
    case .document(let document):
      _ = try? manager.rename(id: document.id, title: title)
    case .search(let search):
      _ = try? searchManager.rename(id: search.id, title: title)
    }
    reload()
  }

  private func remove(_ item: iosSavedItem) {
    switch item {
    case .document(let document):
      manager.delete(id: document.id)
    case .search(let search):
      searchManager.delete(id: search.id)
    }
    reload()
  }
}

/// A chip for where a saved item searched, or its date field
struct iosSavedChip: View {
  var icon: String
  var text: String

  var body: some View {
    HStack(spacing: 3) {
      Image(systemName: icon)
        .font(.system(size: 10))
      Text(text)
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .padding(.horizontal, 7)
    .padding(.vertical, 3)
    .background(Color("BackgroundFixedShadow"))
    .foregroundColor(Color("TextSecondary"))
    .clipShape(Capsule())
  }
}

struct iosSavedSearchRowView: View {
  var search: SavedSearch
  var onRun: () -> Void

  /// eg. "Last 24 hours · 2 filters · 5 fields"
  var details: String {
    var parts: [String] = []
    if let period = search.periodTitle {
      parts.append(period)
    }
    let filters = search.fieldFilters.count
    if filters > 0 {
      parts.append("\(filters) \(filters == 1 ? "filter" : "filters")")
    }
    let columns = search.selectedFields.count
    if columns > 0 {
      parts.append("\(columns) \(columns == 1 ? "field" : "fields")")
    }
    return parts.joined(separator: " · ")
  }

  var body: some View {
    Button(action: onRun) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 16))
          .foregroundColor(Color("AccentColor"))
          .frame(width: 22)
          .padding(.top, 2)

        VStack(alignment: .leading, spacing: 5) {
          Text(search.displayTitle)
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(Color("TextColor"))
            .lineLimit(1)
            .truncationMode(.middle)

          if !search.query.isEmpty && search.query != search.displayTitle {
            Text(search.query)
              .font(.system(size: 13, design: .monospaced))
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
          }

          HStack(spacing: 6) {
            iosSavedChip(icon: "magnifyingglass", text: search.searchIndex)
            if let field = search.dateField {
              iosSavedChip(icon: "clock", text: field.field)
            }
          }

          if !details.isEmpty {
            HStack(spacing: 4) {
              // A period that moves with time, eg. "Last hour", searches up to when it's run
              if search.isPeriodLive {
                Image(systemName: "clock.arrow.circlepath")
                  .font(.system(size: 11))
              }
              Text(details)
                .font(.system(size: 12))
                .lineLimit(2)
            }
            .foregroundColor(Color("TextSecondary"))
          }
        }

        Spacer(minLength: 0)

        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(Color("TextSecondary"))
          .padding(.top, 4)
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color("Button"))
      .cornerRadius(5)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityHint("Runs this search in Search")
  }
}

struct iosSavedDocumentRowView: View {
  var document: SavedDocument

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "doc.text")
        .font(.system(size: 16))
        .foregroundColor(Color("AccentColor"))
        .frame(width: 22)
        .padding(.top, 2)

      VStack(alignment: .leading, spacing: 5) {
        Text(document.displayTitle)
          .font(.system(size: 17, weight: .medium))
          .foregroundColor(Color("TextColor"))
          .lineLimit(1)
          .truncationMode(.middle)

        if !document.title.isEmpty {
          Text(SavedDocument.defaultTitle(for: document.ref))
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
            .truncationMode(.middle)
        }

        if !document.searchIndex.isEmpty || document.dateField != nil {
          HStack(spacing: 6) {
            if !document.searchIndex.isEmpty {
              iosSavedChip(icon: "magnifyingglass", text: document.searchIndex)
            }
            if let field = document.dateField {
              iosSavedChip(icon: "clock", text: field.field)
            }
          }
        }

        if let period = document.periodTitle {
          Text(period)
            .font(.system(size: 12))
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
        }
      }

      Spacer(minLength: 0)

      Image(systemName: "chevron.right")
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(Color("TextSecondary"))
        .padding(.top, 4)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .cornerRadius(5)
    .contentShape(Rectangle())
  }
}
#endif
