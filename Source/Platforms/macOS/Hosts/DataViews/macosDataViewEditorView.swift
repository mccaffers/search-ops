// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
enum DataViewEditorStep {
  case indexes
  case fields
}

/// Creates a data view when `dataViewId` is nil, otherwise edits it.
/// Two steps below the name and pattern: the indexes the pattern matches, then its fields.
/// Works on a draft: nothing is written until Create or Save.
struct macosDataViewEditorView: View {
  var host: HostDetails
  var dataViewId: UUID?
  var onClose: () -> Void

  // The stored view, or a blank one when creating
  @State private var original: DataView? = nil
  @State private var draft: DataView? = nil
  @State private var step: DataViewEditorStep = .indexes
  @State private var saveError: String? = nil
  @State private var showSaved: Bool = false
  @State private var savedFlash = UUID()
  @State private var showDiscardAlert: Bool = false
  @State private var showDeleteAlert: Bool = false
  @State private var isBackHovered: Bool = false

  // Step 1: the indexes the pattern matches
  @State private var indexStats: [String: IndexStatsItem] = [:]
  @State private var statsPattern: String? = nil
  @State private var statsError: String? = nil
  @State private var isLoadingStats: Bool = false
  @State private var statsTask: Task<Void, Never>? = nil

  // Step 2: the fields in their mappings
  @State private var mappingFields: [SquashedFieldsArray] = []
  @State private var dateFields: [DateFieldInfo] = []
  @State private var mappingPattern: String? = nil
  @State private var mappingError: String? = nil
  @State private var isLoadingMapping: Bool = false
  @State private var loadingMappingPattern: String? = nil
  @State private var mappingTask: Task<Void, Never>? = nil

  @State private var fieldFilter: String = ""
  @State private var showStaleLabels: Bool = false
  // The field whose details are showing over the editor
  @State private var inspectedField: String? = nil

  private let manager = DataViewDataManager()

  private var isNew: Bool { dataViewId == nil }

  private var pattern: String {
    draft?.normalized().pattern ?? ""
  }

  private var hasChanges: Bool {
    guard let draft = draft, let original = original else { return false }
    return draft.hasChanges(comparedTo: original)
  }

  private var validationError: DataViewError? {
    guard let draft = draft else { return nil }
    return manager.validate(draft)
  }

  // A new view is created from the fields step, an existing one can be saved from either
  private var canSave: Bool {
    hasChanges && validationError == nil && (!isNew || step == .fields)
  }

  private var statsAreCurrent: Bool {
    !isLoadingStats && statsPattern == pattern
  }

  private var canGoToFields: Bool {
    DataViewPattern.validate(pattern) == nil && statsAreCurrent && statsError == nil
  }

  private var mappingIsCurrent: Bool {
    !isLoadingMapping && mappingPattern == pattern && mappingError == nil
  }

  private var sortedIndexNames: [String] {
    DataViewPattern.sortedIndexNames(indexStats.keys)
  }

  // An empty pattern lists every index on the cluster, as if it were "*"
  private var isBrowsingAll: Bool {
    DataViewPattern.validate(pattern) == .patternEmpty
  }

  /// The pattern can be looked up: valid, or empty to list every index
  private var canCheckPattern: Bool {
    isBrowsingAll || DataViewPattern.validate(pattern) == nil
  }

  /// Labels whose field isn't in the mapping. Only once the mapping has loaded:
  /// if it failed, every label would look stale.
  private var staleLabels: [(field: String, label: String)] {
    guard let draft = draft, mappingIsCurrent else { return [] }
    let known = Set(mappingFields.map(\.squashedString))
    return draft.normalized().labels
      .filter { !known.contains($0.key) }
      .map { (field: $0.key, label: $0.value) }
      .sorted { $0.field < $1.field }
  }

  private var labelledCount: Int {
    guard let draft = draft else { return 0 }
    let known = Set(mappingFields.map(\.squashedString))
    return draft.normalized().labels.keys.filter { known.contains($0) }.count
  }

  private var filteredFields: [SquashedFieldsArray] {
    Self.filter(mappingFields, labels: draft?.labels ?? [:], by: fieldFilter)
  }

  static func filter(_ fields: [SquashedFieldsArray], labels: [String: String], by searchText: String) -> [SquashedFieldsArray] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return fields
    }
    return fields.filter {
      $0.squashedString.localizedCaseInsensitiveContains(trimmed) ||
      $0.type.localizedCaseInsensitiveContains(trimmed) ||
      (labels[$0.squashedString]?.localizedCaseInsensitiveContains(trimmed) ?? false)
    }
  }

  private var editorContent: some View {
    VStack(alignment: .leading, spacing: 10) {
      header

      if draft != nil {
        detailsSection
        stepBar

        switch step {
        case .indexes:
          indexesSection
        case .fields:
          fieldsSection
        }
      } else {
        Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  /// A field's details over the editor, with a dimmed backdrop that closes it when clicked
  @ViewBuilder
  private var fieldOverlay: some View {
    if let path = inspectedField, let field = mappingFields.first(where: { $0.squashedString == path }) {
      RoundedRectangle(cornerRadius: 5)
        .fill(Color.black.opacity(0.3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 5))
        .onTapGesture {
          inspectedField = nil
        }

      macosDataViewFieldDetailView(
        host: host,
        pattern: pattern,
        timeField: draft?.normalized().timeField ?? "",
        field: field,
        label: draft?.labels[path] ?? "",
        onSave: { newLabel in
          draft?.labels[path] = newLabel.isEmpty ? nil : newLabel
          saveError = nil
          inspectedField = nil
        },
        onClose: { inspectedField = nil }
      )
      // A fresh panel for each field
      .id(path)
    }
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      editorContent
      fieldOverlay
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      load()
    }
    .onDisappear {
      statsTask?.cancel()
      mappingTask?.cancel()
    }
    .onChange(of: pattern) { _ in
      schedulePatternCheck()
    }
    .alert("Discard Changes?", isPresented: $showDiscardAlert) {
      Button("Keep Editing", role: .cancel) { }
      Button("Discard", role: .destructive) {
        onClose()
      }
    } message: {
      Text("Your changes to this data view haven't been saved.")
    }
    .alert("Delete Data View?", isPresented: $showDeleteAlert, presenting: original) { view in
      Button("Cancel", role: .cancel) { }
      Button("Delete", role: .destructive) {
        manager.delete(id: view.id)
        onClose()
      }
    } message: { view in
      Text(macosManageDataViewsView.deleteMessage(for: view))
    }
  }

  // MARK: - Header

  private var header: some View {
    HStack(spacing: 8) {
      Button(action: back) {
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
      .help("Back to data views")

      VStack(alignment: .leading, spacing: 2) {
        Text(isNew ? "New data view" : (original?.name ?? "Data view"))
          .font(.system(size: 20, weight: .light))
          .lineLimit(1)
        if !host.isInvalidated {
          Text(host.name)
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
        }
      }

      Spacer()

      if let saveError = saveError {
        Text(saveError)
          .font(.system(size: 12))
          .foregroundColor(.orange)
          .lineLimit(2)
      }

      if !isNew && original != nil {
        Button("Delete") {
          showDeleteAlert = true
        }
        .buttonStyle(macosDataViewButtonStyle(destructive: true))
        .help("Delete this data view")
      }

      Button(showSaved ? "Saved" : (isNew ? "Create" : "Save"), action: save)
        .buttonStyle(macosDataViewButtonStyle(confirmed: showSaved))
        .disabled(!canSave)
        .keyboardShortcut("s", modifiers: .command)
        .help(isNew
              ? (step == .fields ? "Create this data view" : "Choose Next to review the fields first")
              : "Save changes")
    }
    .padding(.top, 10)
    .padding(.bottom, 2)
  }

  // MARK: - Name and pattern

  private var detailsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      formRow("Name") {
        TextField("eg. Backtesting experiments", text: binding(\.name))
          .textFieldStyle(PlainTextFieldStyle())
          .font(.system(size: 13))
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(Color("BackgroundFixedShadow"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
      } footer: {
        if validationError == .nameTaken {
          message(DataViewError.nameTaken.message, icon: "exclamationmark.triangle.fill", color: .orange)
        }
      }

      formRow("Index pattern") {
        TextField("eg. logs-* or logs-*,metrics-*", text: binding(\.pattern))
          .textFieldStyle(PlainTextFieldStyle())
          .font(.system(size: 13, design: .monospaced))
          .disableAutocorrection(true)
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(Color("BackgroundFixedShadow"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .onSubmit {
            if step == .indexes && canGoToFields {
              goToFields()
            }
          }
      } footer: {
        patternStatus
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button").opacity(0.5))
    .clipShape(.rect(cornerRadius: 5))
  }

  @ViewBuilder
  private var patternStatus: some View {
    if let error = DataViewPattern.validate(pattern) {
      if error != .patternEmpty {
        message(error.message, icon: "exclamationmark.triangle.fill", color: .orange)
      }
    } else if !statsAreCurrent {
      HStack(spacing: 6) {
        ProgressView()
          .controlSize(.small)
        Text("Checking pattern…")
          .font(.caption)
          .foregroundColor(Color("TextSecondary"))
      }
    } else if let statsError = statsError {
      message(statsError, icon: "exclamationmark.triangle.fill", color: .orange)
    } else if indexStats.isEmpty {
      message("Matches no indexes yet", icon: "info.circle", color: Color("TextSecondary"))
    } else {
      message(indexStats.count == 1 ? "Matches 1 index" : "Matches \(indexStats.count) indexes",
              icon: "checkmark.circle.fill", color: .green)
    }
  }

  // MARK: - Steps

  private var stepBar: some View {
    HStack(spacing: 6) {
      macosSettingsSegment(title: "1  Indexes", selected: step == .indexes) {
        step = .indexes
      }
      Image(systemName: "chevron.right")
        .font(.system(size: 9, weight: .semibold))
        .foregroundColor(Color("TextSecondary"))
      macosSettingsSegment(title: "2  Fields", selected: step == .fields) {
        goToFields()
      }
      .disabled(!canGoToFields && step != .fields)

      Spacer()

      if step == .indexes {
        Button(action: goToFields) {
          HStack(spacing: 4) {
            Text("Next")
            Image(systemName: "chevron.right")
              .font(.system(size: 10, weight: .semibold))
          }
        }
        .buttonStyle(macosDataViewButtonStyle())
        .disabled(!canGoToFields)
        .help("Review the fields in these indexes")
      }
    }
  }

  // MARK: - Step 1: indexes

  @ViewBuilder
  private var indexesSection: some View {
    if !canCheckPattern {
      placeholder(icon: "rectangle.stack",
                  title: "Enter an index pattern",
                  detail: "Use * to match a series of indexes, eg. backtesting-experiments-*")
    } else if !statsAreCurrent {
      VStack {
        ProgressView()
          .controlSize(.small)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if let statsError = statsError {
      placeholder(icon: "exclamationmark.triangle",
                  title: "Couldn't check the pattern",
                  detail: statsError)
    } else if indexStats.isEmpty && isBrowsingAll {
      placeholder(icon: "rectangle.stack",
                  title: "This cluster has no indexes yet",
                  detail: "Type the pattern your indexes will use, eg. backtesting-experiments-*")
    } else if indexStats.isEmpty {
      placeholder(icon: "magnifyingglass",
                  title: "No indexes match yet",
                  detail: "You can still continue, eg. for indexes that haven't been created.")
    } else {
      VStack(alignment: .leading, spacing: 4) {
        if isBrowsingAll {
          Text("All \(indexStats.count) indexes on this cluster. Pick one, or type a pattern to narrow the list.")
            .font(.caption)
            .foregroundColor(Color("TextSecondary"))
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
        }

        HStack(spacing: 8) {
          Text("Index")
            .frame(maxWidth: .infinity, alignment: .leading)
          Text("Documents")
            .frame(width: 110, alignment: .trailing)
          Text("Size")
            .frame(width: 90, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(Color("TextSecondary"))
        .padding(.horizontal, 10)

        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(sortedIndexNames, id: \.self) { name in
              macosDataViewIndexRowView(indexName: name, stats: indexStats[name]) {
                useIndex(name)
              }
            }
          }
        }
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
  }

  // MARK: - Step 2: time field and labels

  @ViewBuilder
  private var fieldsSection: some View {
    if DataViewPattern.validate(pattern) != nil {
      placeholder(icon: "rectangle.stack",
                  title: "Enter an index pattern",
                  detail: "The fields come from the indexes the pattern matches.")
    } else if isLoadingMapping || mappingPattern != pattern {
      VStack {
        ProgressView()
          .controlSize(.small)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if let mappingError = mappingError {
      placeholder(icon: "exclamationmark.triangle",
                  title: "Couldn't load the fields",
                  detail: mappingError)
    } else {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 12) {
          Text("Time field")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color("TextSecondary"))
          SwiftUI.Picker("", selection: binding(\.timeField)) {
            Text("None").tag("")
            if let timeField = draft?.timeField, !timeField.isEmpty,
               !dateFields.contains(where: { $0.name == timeField }) {
              Text("\(timeField) (not in mapping)").tag(timeField)
            }
            ForEach(dateFields, id: \.name) { field in
              Text(field.name).tag(field.name)
            }
          }
          .labelsHidden()
          .pickerStyle(.menu)
          .frame(maxWidth: 280, alignment: .leading)
          Text("The default date field when searching this data view.")
            .font(.caption)
            .foregroundColor(Color("TextSecondary"))
          Spacer()
        }

        HStack(spacing: 8) {
          Text("Field labels")
            .font(.system(size: 13, weight: .semibold))
          Text("\(mappingFields.count) fields · \(labelledCount) labelled")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color("TextSecondary"))
          Spacer()
        }
        .padding(.top, 4)

        HStack(spacing: 6) {
          Image(systemName: "magnifyingglass")
            .foregroundColor(Color("TextSecondary"))
            .font(.system(size: 12))
          TextField("Filter fields or labels...", text: $fieldFilter)
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 12))
            .onExitCommand {
              fieldFilter = ""
            }
          if !fieldFilter.isEmpty {
            Button(action: { fieldFilter = "" }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(Color("TextSecondary"))
                .font(.system(size: 11))
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color("Button"))
        .clipShape(RoundedRectangle(cornerRadius: 5))

        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            if !staleLabels.isEmpty {
              staleLabelsSection
            }

            if mappingFields.isEmpty {
              Text("No fields found for this pattern.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 30)
            } else if filteredFields.isEmpty {
              Text("No matching fields")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 30)
            } else {
              ForEach(filteredFields, id: \.squashedString) { field in
                macosDataViewFieldRowView(field: field, label: draft?.labels[field.squashedString] ?? "") {
                  inspectedField = field.squashedString
                }
              }
            }
          }
        }
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
  }

  private var staleLabelsSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 6) {
        Button(action: { withAnimation { showStaleLabels.toggle() } }) {
          HStack(spacing: 6) {
            Image(systemName: showStaleLabels ? "chevron.down" : "chevron.right")
              .font(.system(size: 10, weight: .semibold))
              .frame(width: 10)
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
              .font(.system(size: 11))
            Text("Labels not in current mapping (\(staleLabels.count))")
              .font(.system(size: 12, weight: .medium))
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())

        Spacer()

        Button("Remove all") {
          for item in staleLabels {
            draft?.labels[item.field] = nil
          }
        }
        .buttonStyle(.link)
        .font(.system(size: 12))
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 10)

      if showStaleLabels {
        ForEach(staleLabels, id: \.field) { item in
          HStack(spacing: 8) {
            Text(item.field)
              .font(.system(size: 12, design: .monospaced))
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
              .truncationMode(.middle)
            Text(item.label)
              .font(.system(size: 12, weight: .medium))
              .lineLimit(1)
            Spacer()
            Button(action: { draft?.labels[item.field] = nil }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(Color("TextSecondary"))
                .font(.system(size: 11))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Remove this label")
          }
          .padding(.vertical, 4)
          .padding(.horizontal, 28)
        }
      }
    }
    .background(Color.orange.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .padding(.bottom, 4)
  }

  // MARK: - Helpers

  private func formRow<Content: View, Footer: View>(_ title: String,
                                                    @ViewBuilder content: () -> Content,
                                                    @ViewBuilder footer: () -> Footer) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(title)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(Color("TextSecondary"))
        .frame(width: 100, alignment: .trailing)
      VStack(alignment: .leading, spacing: 4) {
        content()
        footer()
      }
    }
  }

  private func message(_ text: String, icon: String, color: Color) -> some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.system(size: 10))
      Text(text)
        .font(.caption)
    }
    .foregroundColor(color)
  }

  private func placeholder(icon: String, title: String, detail: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 24))
        .foregroundColor(Color("TextSecondary"))
      Text(title)
        .font(.headline)
      Text(detail)
        .font(.subheadline)
        .foregroundColor(Color("TextSecondary"))
        .multilineTextAlignment(.center)
        .frame(maxWidth: 420)
        .textSelection(.enabled)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private func binding(_ keyPath: WritableKeyPath<DataView, String>) -> Binding<String> {
    Binding(
      get: { draft?[keyPath: keyPath] ?? "" },
      set: { newValue in
        draft?[keyPath: keyPath] = newValue
        saveError = nil
      }
    )
  }

  // MARK: - Actions

  private func load() {
    guard draft == nil else { return }
    guard !host.isInvalidated else {
      onClose()
      return
    }
    if let id = dataViewId {
      guard let stored = manager.view(id: id) else {
        onClose()
        return
      }
      original = stored
      draft = stored
      step = .fields
    } else {
      let blank = DataView(hostId: host.id)
      original = blank
      draft = blank
      step = .indexes
    }
    schedulePatternCheck(immediately: true)
  }

  private func back() {
    if hasChanges {
      showDiscardAlert = true
    } else {
      onClose()
    }
  }

  /// Narrows the pattern to one of the matched indexes. Its stats are already loaded, so nothing is fetched.
  private func useIndex(_ name: String) {
    statsTask?.cancel()
    indexStats = indexStats[name].map { [name: $0] } ?? [:]
    statsPattern = name
    statsError = nil
    isLoadingStats = false
    draft?.pattern = name
    saveError = nil
  }

  private func goToFields() {
    guard canGoToFields || step == .fields else { return }
    step = .fields
    loadMappingIfNeeded()
  }

  private func save() {
    guard let draft = draft, canSave else { return }
    do {
      if isNew {
        try manager.create(draft)
        onClose()
      } else {
        let updated = try manager.update(draft)
        original = updated
        self.draft = updated
        flashSaved()
      }
    } catch let error as DataViewError {
      saveError = error.message
    } catch {
      saveError = error.localizedDescription
    }
  }

  private func flashSaved() {
    let flash = UUID()
    savedFlash = flash
    withAnimation(.easeInOut(duration: 0.3)) {
      showSaved = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      guard flash == savedFlash else { return }
      withAnimation(.easeInOut(duration: 0.3)) {
        showSaved = false
      }
    }
  }

  /// Checks which indexes the pattern matches, after a pause in typing. An empty pattern lists every index.
  /// On the fields step, the fields reload for the new pattern too.
  private func schedulePatternCheck(immediately: Bool = false) {
    statsTask?.cancel()
    let pattern = self.pattern
    guard canCheckPattern, !host.isInvalidated else {
      isLoadingStats = false
      return
    }
    guard pattern != statsPattern else {
      isLoadingStats = false
      if step == .fields {
        loadMappingIfNeeded()
      }
      return
    }

    let detachedHost = host.generateCopy()
    statsTask = Task {
      if !immediately {
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard !Task.isCancelled else { return }
      }
      await MainActor.run {
        isLoadingStats = true
      }

      let response = await Indicies.indexStats(serverDetails: detachedHost, index: pattern)

      guard !Task.isCancelled else { return }

      await MainActor.run {
        if response.httpStatus == 404 {
          // An exact name that doesn't exist yet. A wildcard that matches nothing returns no indices instead.
          statsError = nil
          indexStats = [:]
        } else if let error = response.error {
          statsError = error.message
          indexStats = [:]
        } else if response.httpStatus >= 400 {
          statsError = response.httpErrorMessage
          indexStats = [:]
        } else {
          statsError = nil
          let string = response.data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
          indexStats = Results.parseIndexStats(string)
        }
        statsPattern = pattern
        isLoadingStats = false
        if step == .fields {
          loadMappingIfNeeded()
        }
      }
    }
  }

  /// Loads the fields for the current pattern, unless they're already loaded
  private func loadMappingIfNeeded() {
    let pattern = self.pattern
    guard DataViewPattern.validate(pattern) == nil, !host.isInvalidated else { return }
    guard pattern != mappingPattern || mappingError != nil else { return }
    if isLoadingMapping && mappingTask != nil && pattern == loadingMappingPattern { return }

    mappingTask?.cancel()
    loadingMappingPattern = pattern
    isLoadingMapping = true
    let detachedHost = host.generateCopy()
    mappingTask = Task {
      let mapping = await IndexManagementService.fetchIndexMapping(serverDetails: detachedHost, index: pattern)

      guard !Task.isCancelled else { return }

      await MainActor.run {
        if mapping.error != nil && indexStats.isEmpty && statsError == nil {
          // No indexes yet, so there are no fields to load
          mappingError = nil
          mappingFields = []
          dateFields = []
        } else if let error = mapping.error {
          mappingError = error.message
          mappingFields = []
          dateFields = []
        } else {
          mappingError = nil
          mappingFields = DataViewPattern.mergeFields(mapping.fields)
          dateFields = mapping.dateFields
        }
        mappingPattern = pattern
        isLoadingMapping = false
      }
    }
  }
}

/// The Manage pages' button: Button, ButtonHighlighted on hover and when pressed,
/// dimmed while disabled, and green while `confirmed` is set, eg. "Saved".
/// `large` matches the height of a page header's back button and title.
struct macosDataViewButtonStyle: ButtonStyle {
  var confirmed = false
  var destructive = false
  var large = false

  func makeBody(configuration: Configuration) -> some View {
    macosDataViewButton(configuration: configuration, confirmed: confirmed, destructive: destructive, large: large)
  }
}

private struct macosDataViewButton: View {
  let configuration: ButtonStyleConfiguration
  let confirmed: Bool
  let destructive: Bool
  let large: Bool

  @Environment(\.isEnabled) private var isEnabled
  @State private var hovering = false

  private var fill: Color {
    if confirmed { return Color("PositiveButton") }
    if isEnabled && (hovering || configuration.isPressed) { return Color("ButtonHighlighted") }
    return Color("Button")
  }

  private var foreground: Color {
    if confirmed { return .white }
    if !isEnabled { return Color("TextSecondary") }
    return destructive ? .red : Color("TextColor")
  }

  var body: some View {
    configuration.label
      .font(.system(size: large ? 13 : 12, weight: .medium))
      .padding(.horizontal, large ? 14 : 12)
      .frame(minHeight: large ? 36 : 26)
      .foregroundColor(foreground)
      .background(RoundedRectangle(cornerRadius: 5).fill(fill))
      .opacity(isEnabled || confirmed ? 1 : 0.6)
      .contentShape(Rectangle())
      .onHover { hovering = $0 }
      .animation(.easeInOut(duration: 0.15), value: hovering)
      .animation(.easeInOut(duration: 0.3), value: confirmed)
  }
}

/// One index the pattern matches, with its document count and size. Clicking it narrows the pattern to it.
struct macosDataViewIndexRowView: View {
  var indexName: String
  var stats: IndexStatsItem?
  var onSelect: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: onSelect) {
      row
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
    .help("Use only \(indexName) as the pattern")
  }

  private var row: some View {
    HStack(spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: indexName.hasPrefix(".") ? "eye.slash" : "cylinder")
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary"))
        Text(indexName)
          .font(.system(size: 13, design: .monospaced))
          .lineLimit(1)
          .truncationMode(.middle)
        if indexName.hasPrefix(".") {
          Text("hidden")
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(Color("BackgroundFixedShadow"))
            .clipShape(Capsule())
            .foregroundColor(Color("TextSecondary"))
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Text(stats?.formattedDocCount ?? "–")
        .frame(width: 110, alignment: .trailing)
      Text(stats?.formattedStorageSize ?? "–")
        .frame(width: 90, alignment: .trailing)
    }
    .font(.system(size: 11, design: .monospaced))
    .foregroundColor(Color("TextColor"))
    .padding(.vertical, 8)
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(isHovered ? Color("ButtonHighlighted") : Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .contentShape(Rectangle())
  }
}

/// A mapped field. Clicking it opens its details; a labelled field shows its label beside the name.
struct macosDataViewFieldRowView: View {
  var field: SquashedFieldsArray
  var label: String
  var onSelect: () -> Void

  @State private var isHovered = false

  private var isDateField: Bool {
    field.type.components(separatedBy: ", ").contains { $0 == "date" || $0 == "date_nanos" }
  }

  private var hasLabel: Bool {
    !label.isEmpty
  }

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 8) {
        Image(systemName: hasLabel ? "tag.fill" : (isDateField ? "calendar.badge.clock" : "tag"))
          .font(.system(size: 11))
          .foregroundColor(hasLabel ? Color.accentColor : (isDateField ? .blue : Color("TextSecondary")))
          .frame(width: 14)

        Text(field.squashedString)
          .font(.system(size: 12, weight: .regular, design: .monospaced))
          .lineLimit(1)
          .truncationMode(.middle)
          .layoutPriority(1)

        if hasLabel {
          Text(label)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .foregroundColor(.white)
            .background(Color.accentColor.opacity(0.35))
            .overlay(
              RoundedRectangle(cornerRadius: 5)
                .stroke(Color.accentColor.opacity(0.8), lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .help("Label: \(label)")
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(Color("TextSecondary"))
          .opacity(isHovered ? 1 : 0)

        macosFieldTypeBadgeView(type: field.type)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 10)
      .background(isHovered ? Color("ButtonHighlighted") : Color("Button"))
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
    .help(hasLabel ? "Edit the label for \(field.squashedString)" : "Add a label for \(field.squashedString)")
  }
}

#Preview {
  let host = HostDetails()
  host.name = "Production Cluster"
  return macosDataViewEditorView(host: host, dataViewId: nil, onClose: {})
    .frame(width: 700, height: 600)
    .padding()
}
#endif
