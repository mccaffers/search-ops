// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
/// Names the search on screen and keeps it in the Saved tab, with its query, time period, sort and fields. A search
/// that came from a saved one can update it instead. A period that moves with time, eg. "Last hour", can stay
/// relative or be pinned to the dates it covers now.
struct iosSaveSearchSheet: View {
  var host: HostDetails?
  var searchIndex: String
  /// The fields picked in Fields, not counting the date field. Empty when every field is shown.
  var selectedFields: [String]
  /// The saved search this search came from, or was saved as, updated as it's saved
  @Binding var link: SavedSearchLink?
  /// What differs from the saved search it came from
  var changes: [SavedSearchState.Part]

  @EnvironmentObject var filterObject: FilterObject
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var pinPeriod = false
  @State private var errorMessage: String? = nil

  private var hostIsValid: Bool {
    guard let host = host else { return false }
    return !host.isInvalidated
  }

  private var trimmedIndex: String {
    searchIndex.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var query: String {
    let query = (filterObject.query?.values.first?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return query == "*" ? "" : query
  }

  /// nil without a date field, as a period means nothing without one
  private var period: DateRangeSnapshot? {
    filterObject.dateField == nil ? nil : filterObject.snapshotDateRange()
  }

  /// Only a period that moves with time has a choice, fixed dates are fixed either way
  private var offersPeriodChoice: Bool {
    period?.isLive ?? false
  }

  private var savesPinned: Bool {
    offersPeriodChoice && pinPeriod
  }

  /// What differs from the saved search, counting a switch between relative and fixed dates
  private var allChanges: [SavedSearchState.Part] {
    SavedSearchState.changes(changes,
                             pinningChanged: link != nil && offersPeriodChoice && pinPeriod != link?.pinnedPeriod)
  }

  private var suggestedName: String {
    SavedSearch.defaultTitle(query: query, index: trimmedIndex, filterCount: 0)
  }

  private var canSave: Bool {
    hostIsValid && !trimmedIndex.isEmpty
  }

  var body: some View {
    NavigationStack {
      Form {
        if let link = link {
          Section {
            VStack(alignment: .leading, spacing: 3) {
              Text(link.title)
                .lineLimit(1)
                .truncationMode(.middle)
              Text(SavedSearchState.changesLabel(allChanges))
                .font(.footnote)
                .foregroundColor(Color("TextSecondary"))
            }
            Button {
              update(link)
            } label: {
              Label("Update \"\(link.title)\"", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(allChanges.isEmpty || !canSave)
          } header: {
            Text("Saved Search")
          } footer: {
            Text(allChanges.isEmpty ? "Nothing has changed since it was saved."
                                    : "Replaces the saved search with this one.")
          }
          .listRowBackground(Color("Button"))
        }

        Section {
          TextField(suggestedName, text: $name)
            .submitLabel(.done)
            .onSubmit(saveNew)
        } header: {
          Text(link == nil ? "Name" : "Save as New Search")
        } footer: {
          if trimmedIndex.isEmpty {
            Label("Choose an index in Hosts to save this search.", systemImage: "exclamationmark.triangle")
          }
        }
        .listRowBackground(Color("Button"))

        Section {
          row("Host", hostIsValid ? host?.name ?? "" : "None")
          row("Index", trimmedIndex.isEmpty ? "None" : trimmedIndex, monospaced: true)
          row("Query", query.isEmpty ? "Every document" : query, monospaced: !query.isEmpty)
          if let dateField = filterObject.dateField {
            row("Date field", dateField.squashedString, monospaced: true)
          }
          if let period = period {
            row("Period", period.title)
          }
          if let sort = filterObject.sort {
            row("Sort", "\(sort.field.squashedString) \(sort.order == .Ascending ? "↑" : "↓")", monospaced: true)
          }
          row("Fields", selectedFields.isEmpty ? "All" : "\(selectedFields.count)")
        } header: {
          Text("Search")
        }
        .listRowBackground(Color("Button"))

        if offersPeriodChoice {
          Section {
            SwiftUI.Picker("Period", selection: $pinPeriod) {
              Text("Relative").tag(false)
              Text("Fixed dates").tag(true)
            }
            .pickerStyle(.segmented)
          } header: {
            Text("Each run searches")
          } footer: {
            Text(periodDescription)
          }
          .listRowBackground(Color("Button"))
        }

        if let errorMessage = errorMessage {
          Section {
            Label(errorMessage, systemImage: "exclamationmark.triangle")
          }
          .listRowBackground(Color("Button"))
        }
      }
      .scrollContentBackground(.hidden)
      .background(Color("Background"))
      .navigationTitle("Save Search")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackgroundVisibleBeforeiOS26()
      .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(link == nil ? "Save" : "Save New", action: saveNew)
            .fontWeight(.semibold)
            .disabled(!canSave)
        }
      }
    }
    .tint(Color("AccentColor"))
    .onAppear {
      // The saved search may have been renamed or removed in the Saved tab
      if let current = link {
        if let saved = SavedSearchDataManager().search(id: current.id) {
          link?.title = saved.displayTitle
          link?.pinnedPeriod = SavedSearchLink.isPinned(saved, baseline: current.baseline)
        } else {
          link = nil
        }
      }
      pinPeriod = link?.pinnedPeriod ?? false
      name = link.map { SavedSearch.copyTitle(of: $0.title) } ?? suggestedName
    }
  }

  private func row(_ title: String, _ value: String, monospaced: Bool = false) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(title)
      Spacer()
      Text(value)
        .font(monospaced ? .system(.body, design: .monospaced) : .body)
        .foregroundColor(Color("TextSecondary"))
        .lineLimit(2)
        .truncationMode(.middle)
        .multilineTextAlignment(.trailing)
    }
  }

  /// eg. "Last hour, whenever it's run", or "Always 9 Oct 2026 at 14:00 – 9 Oct 2026 at 15:00"
  private var periodDescription: String {
    guard let period = period else { return "" }
    if pinPeriod, let fixed = SavedSearch.savedPeriod(period, pinned: true) {
      return "Always \(fixed.title)"
    }
    return "\(period.title), whenever it's run"
  }

  /// The search as it stands, as a saved search
  private func currentSearch(title: String = "") -> SavedSearch? {
    guard canSave, let host = host else { return nil }
    return SavedSearch.make(hostId: host.id,
                            title: title,
                            searchIndex: trimmedIndex,
                            dataView: nil,
                            filterObject: filterObject,
                            selectedFields: selectedFields,
                            pinPeriod: savesPinned)
  }

  /// The search as far as saving goes, to tell later whether it's changed
  private var currentState: SavedSearchState {
    SavedSearchState(searchIndex: trimmedIndex,
                     dataViewId: nil,
                     filterObject: filterObject,
                     selectedFields: selectedFields)
  }

  /// Saves the search as a new saved search, which saving again then updates
  private func saveNew() {
    guard let search = currentSearch(title: name) else { return }
    do {
      let saved = try SavedSearchDataManager().save(search)
      let baseline = currentState
      link = SavedSearchLink(id: saved.id, title: saved.displayTitle, baseline: baseline,
                             pinnedPeriod: SavedSearchLink.isPinned(saved, baseline: baseline))
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      dismiss()
    } catch {
      errorMessage = (error as? SavedDocumentError)?.message ?? error.localizedDescription
    }
  }

  /// Replaces the saved search this search came from with the search as it stands
  private func update(_ current: SavedSearchLink) {
    guard let search = currentSearch() else { return }
    do {
      let saved = try SavedSearchDataManager().update(id: current.id, with: search)
      let baseline = currentState
      link?.baseline = baseline
      link?.pinnedPeriod = SavedSearchLink.isPinned(saved, baseline: baseline)
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      dismiss()
    } catch {
      // Removed from the Saved tab meanwhile, so it can only be saved as a new one
      link = nil
      errorMessage = "The saved search no longer exists. Save it as a new search instead."
    }
  }
}
#endif
