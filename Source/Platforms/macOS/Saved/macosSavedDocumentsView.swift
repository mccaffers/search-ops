// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

/// Hands a search from the Saved tab to the Search tab, which runs it when it hears about it
@MainActor
final class macosSearchHandoff: ObservableObject {
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

/// Loading the document open in the Saved tab
enum macosSavedDocumentLoadState: Equatable {
  case idle
  case loading
  case loaded
  case notFound
  case failed(String)
}

/// A saved document or search, for renaming and removing either
enum macosSavedItem: Identifiable {
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

struct macosSavedDocumentsView: View {
  @Binding var fullScreen: Bool
  @ObservedObject var serverObjects: HostsDataManager
  /// Runs a saved search, or a search for one of the open document's values, in the Search tab
  var onSearch: (SearchHandoffRequest) -> Void

  @State private var documents: [SavedDocument] = []
  @State private var searches: [SavedSearch] = []
  @State private var dataViewNames: [UUID: String] = [:]
  @State private var selected: SavedDocument? = nil
  @State private var loadState: macosSavedDocumentLoadState = .idle
  @State private var loadTask: Task<Void, Never>? = nil
  @State private var message: String? = nil

  // The Document panel
  @StateObject private var itemDetail = DocumentDetail()
  @State private var fields: [SquashedFieldsArray] = []
  @State private var onlyVisibleFields: [SquashedFieldsArray] = []
  @State private var fieldsVersion = UUID()
  @State private var labels: [String: String] = [:]
  @AppStorage("macosDocumentPanelFraction") private var documentPanelFraction: Double = macosSearchMainView.defaultDocumentPanelFraction

  @State private var pendingRename: macosSavedItem? = nil
  @State private var renameText = ""
  @State private var pendingDelete: macosSavedItem? = nil
  @State private var confirmingClearAll = false
  /// Remembered between visits, as it's a way of looking at the tab rather than part of what's saved
  @AppStorage("macosSavedItemFilter") private var filterRaw: String = SavedItemFilter.all.rawValue

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
    ZStack(alignment: .topTrailing) {
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

        if allGroups.isEmpty {
          emptyState
        } else if groups.isEmpty {
          Text(filter == .searches ? "No saved searches" : "No saved documents")
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
              ForEach(groups) { group in
                Text(group.hostName)
                  .font(.system(size: 13, weight: .medium))
                  .foregroundColor(Color("TextSecondary"))
                  .padding(.top, group.id == groups.first?.id ? 0 : 10)
                  .padding(.bottom, 2)

                ForEach(group.searches) { search in
                  macosSavedSearchRowView(
                    search: search,
                    dataViewName: search.dataViewId.flatMap { dataViewNames[$0] },
                    onRun: { run(search) },
                    onRename: {
                      renameText = search.title
                      pendingRename = .search(search)
                    },
                    onDelete: { pendingDelete = .search(search) }
                  )
                }

                ForEach(group.documents) { document in
                  macosSavedDocumentRowView(
                    document: document,
                    dataViewName: document.dataViewId.flatMap { dataViewNames[$0] },
                    isSelected: selected?.id == document.id,
                    loadState: selected?.id == document.id ? loadState : .idle,
                    onOpen: { open(document) },
                    onRename: {
                      renameText = document.title
                      pendingRename = .document(document)
                    },
                    onDelete: { pendingDelete = .document(document) }
                  )
                }
              }
            }
            .padding(.bottom, 10)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

      if selected != nil && itemDetail.item != nil {
        // Dims the list behind the panel, as Search does, and clicking it closes the panel
        RoundedRectangle(cornerRadius: 5)
          .fill(Color.black.opacity(0.3))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .contentShape(RoundedRectangle(cornerRadius: 5))
          .onTapGesture {
            closeDocument()
          }
          // Covers the page's side padding too
          .padding(.horizontal, -10)
          .accessibilityLabel("Close document")
          .accessibilityAddTraits(.isButton)

        // The panel takes its saved share of the page, as it does in Search
        GeometryReader { geometry in
          let available = geometry.size.width
          macosDocumentDetailView(itemDetail: itemDetail,
                                  fields: $fields,
                                  onlyVisibleFields: $onlyVisibleFields,
                                  updatedFieldsNotification: $fieldsVersion,
                                  labels: labels,
                                  width: macosSearchMainView.clampedDocumentPanelWidth(documentPanelFraction * available,
                                                                                      available: available),
                                  availableWidth: available,
                                  onResized: { width in
                                    if available > 0 {
                                      documentPanelFraction = width / available
                                    }
                                  },
                                  onResetWidth: {
                                    documentPanelFraction = macosSearchMainView.defaultDocumentPanelFraction
                                  },
                                  onFilter: search(field:value:negated:),
                                  onClose: closeDocument,
                                  isSaved: true,
                                  onToggleSaved: unsaveOpenDocument,
                                  showsFieldVisibility: false,
                                  topPadding: 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        // Sits over the page's side padding, as the panel does in Search
        .padding(.trailing, -10)
      }
    }
    .padding(.horizontal, 10)
    .background(Color("BackgroundFixedShadow"))
    .clipShape(.rect(cornerRadius: 5))
    .padding(.leading, 3)
    .padding(.trailing, 5)
    .padding(.bottom, 5)
    .padding(.top, fullScreen ? 5 : 0)
    .onAppear {
      serverObjects.refresh()
      reload()
    }
    .onDisappear {
      loadTask?.cancel()
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
    .alert("\(Self.clearTitle(filter))?", isPresented: $confirmingClearAll) {
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
        switch item {
        case .document(let document):
          remove(document)
        case .search(let search):
          searchManager.delete(id: search.id)
          reload()
        }
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

  private var header: some View {
    HStack(spacing: 6) {
      Text("Saved")
        .font(.system(size: 22, weight: .light))
      if !groups.isEmpty {
        Text("\(groups.reduce(0) { $0 + $1.count })")
          .font(.system(size: 12, weight: .semibold))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .foregroundColor(Color("TextSecondary"))
      }
      Spacer()
      if !allGroups.isEmpty {
        filterSwitch
      }
      if !groups.isEmpty {
        Button {
          confirmingClearAll = true
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "trash")
            Text(Self.clearTitle(filter))
          }
        }
        .buttonStyle(macosDataViewButtonStyle(destructive: true))
        .help(Self.clearHelp(filter))
      }
    }
    .padding(.top, 10)
    .padding(.bottom, 5)
  }

  private var emptyState: some View {
    VStack(spacing: 8) {
      Image(systemName: "bookmark")
        .font(.system(size: 28))
        .foregroundColor(Color("TextSecondary"))
      Text("Nothing saved yet")
        .font(.headline)
      Text("Click Save above a search to keep its query, filters, columns and time period here, or open a document in Search and click Save to keep that document.")
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
    let dataViews = DataViewDataManager()
    var names: [UUID: String] = [:]
    for id in Set(documents.compactMap(\.dataViewId) + searches.compactMap(\.dataViewId)) {
      if let view = dataViews.view(id: id) {
        names[id] = view.name
      }
    }
    dataViewNames = names
    if let open = selected, !documents.contains(where: { $0.id == open.id }) {
      closeDocument()
    }
  }

  private func host(for document: SavedDocument) -> HostDetails? {
    host(id: document.hostId)
  }

  private func host(id: UUID) -> HostDetails? {
    guard let host = serverObjects.getHostByID(id), !host.isInvalidated else { return nil }
    return host
  }

  /// Runs a saved search in the Search tab, with its columns
  private func run(_ search: SavedSearch) {
    guard host(id: search.hostId) != nil else {
      message = "The host this search was saved from no longer exists."
      return
    }
    let dataView = search.dataViewId.flatMap { DataViewDataManager().view(id: $0) }
    onSearch(search.request(dataView: dataView))
  }

  private var filterSwitch: some View {
    HStack(spacing: 2) {
      ForEach(SavedItemFilter.allCases, id: \.self) { option in
        macosSettingsSegment(title: option.title, selected: filter == option) {
          filterRaw = option.rawValue
        }
      }
    }
    .padding(2)
    .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
  }

  static func clearTitle(_ filter: SavedItemFilter) -> String {
    switch filter {
    case .all: return "Clear All"
    case .documents: return "Clear Documents"
    case .searches: return "Clear Searches"
    }
  }

  static func clearHelp(_ filter: SavedItemFilter) -> String {
    switch filter {
    case .all: return "Remove every saved search and document"
    case .documents: return "Remove every saved document"
    case .searches: return "Remove every saved search"
    }
  }

  /// eg. "All 3 saved items will be removed from this Mac. Documents on the cluster aren't affected."
  static func clearMessage(_ filter: SavedItemFilter, count: Int) -> String {
    let noun: String
    switch filter {
    case .all: noun = count == 1 ? "saved item" : "saved items"
    case .documents: noun = count == 1 ? "saved document" : "saved documents"
    case .searches: noun = count == 1 ? "saved search" : "saved searches"
    }
    let items = count == 1 ? "The \(noun)" : "All \(count) \(noun)"
    let cluster = filter == .searches ? "" : " Documents on the cluster aren't affected."
    return "\(items) will be removed from this Mac.\(cluster)"
  }

  /// Removes the kind of saved item the switch shows
  private func clear(_ filter: SavedItemFilter) {
    if filter != .searches {
      closeDocument()
      manager.deleteAll()
    }
    if filter != .documents {
      searchManager.deleteAll()
    }
    reload()
  }

  private func rename(_ item: macosSavedItem, to title: String) {
    switch item {
    case .document(let document):
      _ = try? manager.rename(id: document.id, title: title)
    case .search(let search):
      _ = try? searchManager.rename(id: search.id, title: title)
    }
    reload()
  }

  /// Fetches the document from the cluster and shows it in the Document panel
  private func open(_ document: SavedDocument) {
    loadTask?.cancel()
    message = nil
    selected = document
    itemDetail.item = nil
    guard let host = host(for: document) else {
      loadState = .failed("This host no longer exists.")
      return
    }
    loadState = .loading
    labels = document.dataViewId.flatMap { DataViewDataManager().view(id: $0) }?.labels ?? [:]
    let hostCopy = host.generateCopy()
    loadTask = Task {
      let result = await SavedDocumentSearch.load(document, host: hostCopy)
      guard !Task.isCancelled, selected?.id == document.id else { return }
      switch result {
      case .found(let content):
        // The mapping gives each field its type badge, as in Search
        let mapping = await IndexMap.indexMappings(serverDetails: hostCopy, index: document.docIndex)
        guard !Task.isCancelled, selected?.id == document.id else { return }
        fields = mapping
        onlyVisibleFields = []
        fieldsVersion = UUID()
        itemDetail.ref = content.ref
        itemDetail.item = content.row
        loadState = .loaded
      case .notFound:
        loadState = .notFound
      case .failed(let error):
        loadState = .failed(error.message)
      }
    }
  }

  private func closeDocument() {
    loadTask?.cancel()
    selected = nil
    loadState = .idle
    itemDetail.item = nil
  }

  /// Searches the Search tab for documents with, or without, one of the open document's values
  private func search(field: String, value: String, negated: Bool) {
    guard let document = selected else { return }
    guard host(for: document) != nil else {
      message = "The host this document was saved from no longer exists."
      return
    }
    let dataView = document.dataViewId.flatMap { DataViewDataManager().view(id: $0) }
    onSearch(SavedDocumentSearch.termSearch(for: document, field: field, value: value, negated: negated,
                                            dataView: dataView))
  }

  private func unsaveOpenDocument() {
    guard let document = selected else { return }
    remove(document)
  }

  private func remove(_ document: SavedDocument) {
    manager.delete(id: document.id)
    if selected?.id == document.id {
      closeDocument()
    }
    reload()
  }
}

struct macosSavedDocumentRowView: View {
  var document: SavedDocument
  /// The name of the data view it was saved from, nil when there's none or it's been deleted
  var dataViewName: String?
  var isSelected: Bool
  var loadState: macosSavedDocumentLoadState
  var onOpen: () -> Void
  var onRename: () -> Void
  var onDelete: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: onOpen) {
      HStack(spacing: 10) {
        Image(systemName: "doc.text")
          .font(.system(size: 14))
          .foregroundColor(Color.accentColor)
          .frame(width: 20)

        VStack(alignment: .leading, spacing: 3) {
          Text(document.displayTitle)
            .font(.system(size: 14, weight: .medium))
            .lineLimit(1)
            .truncationMode(.middle)

          if !document.title.isEmpty {
            Text(SavedDocument.defaultTitle(for: document.ref))
              .font(.system(size: 12, design: .monospaced))
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
              .truncationMode(.middle)
          }

          HStack(spacing: 6) {
            if let name = dataViewName {
              chip(icon: "rectangle.stack", text: name)
            } else if !document.searchIndex.isEmpty {
              chip(icon: "magnifyingglass", text: document.searchIndex)
            }
            if let field = document.dateField {
              chip(icon: "clock", text: field.field)
            }
            if let period = document.periodTitle {
              Text(period)
                .font(.system(size: 11))
                .foregroundColor(Color("TextSecondary"))
                .lineLimit(1)
            }
          }

          status
        }

        Spacer()

        if loadState == .loading {
          ProgressView()
            .controlSize(.small)
        }

        Menu {
          menuItems
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color("TextSecondary"))
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More actions")

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(Color("TextSecondary"))
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(isHovered || isSelected ? Color("ButtonHighlighted") : Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
    .contextMenu {
      menuItems
    }
    .help("Saved \(document.savedDate.formatted(date: .abbreviated, time: .shortened))")
  }

  @ViewBuilder
  private var menuItems: some View {
    Button("Open", action: onOpen)
    Button("Rename…", action: onRename)
    Button("Copy Document ID") {
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(document.docId, forType: .string)
    }
    Divider()
    Button("Remove…", role: .destructive, action: onDelete)
  }

  @ViewBuilder
  private var status: some View {
    switch loadState {
    case .notFound:
      Text("This document no longer exists on the cluster.")
        .font(.system(size: 11))
        .foregroundColor(Color("WarnText"))
    case .failed(let reason):
      Text(reason)
        .font(.system(size: 11))
        .foregroundColor(Color("WarnText"))
        .lineLimit(2)
    case .idle, .loading, .loaded:
      EmptyView()
    }
  }

  private func chip(icon: String, text: String) -> some View {
    HStack(spacing: 3) {
      Image(systemName: icon)
        .font(.system(size: 9))
      Text(text)
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(Color("BackgroundFixedShadow"))
    .foregroundColor(Color("TextSecondary"))
    .clipShape(Capsule())
  }
}

struct macosSavedSearchRowView: View {
  var search: SavedSearch
  /// The name of the data view it was saved from, nil when there's none or it's been deleted
  var dataViewName: String?
  var onRun: () -> Void
  var onRename: () -> Void
  var onDelete: () -> Void

  @State private var isHovered = false

  /// eg. "Run this search. Saved 9 Oct 2026 at 14:00, updated 10 Oct 2026 at 09:30"
  var helpText: String {
    var text = "Run this search. Saved \(search.savedDate.formatted(date: .abbreviated, time: .shortened))"
    if let updated = search.updatedDate {
      text += ", updated \(updated.formatted(date: .abbreviated, time: .shortened))"
    }
    return text
  }

  /// eg. "2 filters · 5 columns"
  var details: String {
    var parts: [String] = []
    let filters = search.fieldFilters.count
    if filters > 0 {
      parts.append("\(filters) \(filters == 1 ? "filter" : "filters")")
    }
    let columns = search.selectedFields.count
    if columns > 0 {
      parts.append("\(columns) \(columns == 1 ? "column" : "columns")")
    }
    return parts.joined(separator: " · ")
  }

  var body: some View {
    Button(action: onRun) {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 14))
          .foregroundColor(Color.accentColor)
          .frame(width: 20)

        VStack(alignment: .leading, spacing: 3) {
          Text(search.displayTitle)
            .font(.system(size: 14, weight: .medium))
            .lineLimit(1)
            .truncationMode(.middle)

          if !search.query.isEmpty && search.query != search.displayTitle {
            Text(search.query)
              .font(.system(size: 12, design: .monospaced))
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
              .truncationMode(.tail)
          }

          HStack(spacing: 6) {
            if let name = dataViewName {
              chip(icon: "rectangle.stack", text: name)
            } else {
              chip(icon: "magnifyingglass", text: search.searchIndex)
            }
            if let field = search.dateField {
              chip(icon: "clock", text: field.field)
            }
            if let period = search.periodTitle {
              Text(period)
                .font(.system(size: 11))
                .foregroundColor(Color("TextSecondary"))
                .lineLimit(1)
            }
            if !details.isEmpty {
              Text(details)
                .font(.system(size: 11))
                .foregroundColor(Color("TextSecondary"))
                .lineLimit(1)
            }
          }
        }

        Spacer()

        Menu {
          menuItems
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color("TextSecondary"))
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More actions")

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(Color("TextSecondary"))
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(isHovered ? Color("ButtonHighlighted") : Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
    .contextMenu {
      menuItems
    }
    .help(helpText)
  }

  @ViewBuilder
  private var menuItems: some View {
    Button("Run Search", action: onRun)
    Button("Rename…", action: onRename)
    Divider()
    Button("Remove…", role: .destructive, action: onDelete)
  }

  private func chip(icon: String, text: String) -> some View {
    HStack(spacing: 3) {
      Image(systemName: icon)
        .font(.system(size: 9))
      Text(text)
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(Color("BackgroundFixedShadow"))
    .foregroundColor(Color("TextSecondary"))
    .clipShape(Capsule())
  }
}
#endif
