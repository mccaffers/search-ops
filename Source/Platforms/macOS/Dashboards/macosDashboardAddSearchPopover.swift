// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

/// Ticks saved searches to add to a dashboard. Saved documents aren't listed, a dashboard only shows searches.
struct macosDashboardAddSearchPopover: View {
  /// Saved searches by host
  var groups: [SavedDocumentGroup]
  /// Searches the dashboard already shows, ticked and greyed out
  var shownIds: Set<UUID>
  var dataViewNames: [UUID: String]
  /// The ticked searches, in list order
  var onAdd: ([UUID]) -> Void
  var onCancel: () -> Void

  @State private var searchText = ""
  @State private var ticked: Set<UUID> = []

  private var shownGroups: [SavedDocumentGroup] {
    SavedTextFilter.apply(searchText, to: groups.filter { !$0.searches.isEmpty }, dataViewNames: dataViewNames)
  }

  /// Ticked searches in the order they're listed
  private var tickedInOrder: [UUID] {
    groups.flatMap(\.searches).map(\.id).filter { ticked.contains($0) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Add Saved Searches")
        .font(.system(size: 14, weight: .semibold))

      filterField

      if shownGroups.isEmpty {
        Text(groups.allSatisfy { $0.searches.isEmpty }
             ? "No saved searches yet. Save a search from the Search tab first."
             : "No saved searches match \"\(searchText.trimmingCharacters(in: .whitespaces))\"")
          .font(.subheadline)
          .foregroundColor(Color("TextSecondary"))
          .frame(maxWidth: .infinity, minHeight: 120)
          .multilineTextAlignment(.center)
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(shownGroups) { group in
              Text(group.hostName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
                .padding(.top, group.id == shownGroups.first?.id ? 0 : 8)

              ForEach(group.searches) { search in
                macosDashboardAddSearchRow(search: search,
                                           dataViewName: search.dataViewId.flatMap { dataViewNames[$0] },
                                           isShown: shownIds.contains(search.id),
                                           isChecked: shownIds.contains(search.id) || ticked.contains(search.id),
                                           onToggle: { toggle(search.id) })
              }
            }
          }
        }
        .frame(maxHeight: 360)
      }

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
          .buttonStyle(macosDataViewButtonStyle())
          .keyboardShortcut(.cancelAction)
        Button(ticked.isEmpty ? "Add" : "Add (\(ticked.count))") {
          onAdd(tickedInOrder)
        }
        .buttonStyle(macosDataViewButtonStyle())
        .keyboardShortcut(.defaultAction)
        .disabled(ticked.isEmpty)
      }
    }
    .padding(14)
    .frame(width: 420)
    .background(Color("BackgroundFixedShadow"))
  }

  private var filterField: some View {
    HStack(spacing: 6) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(Color("TextSecondary"))
        .font(.system(size: 12))

      TextField("Filter saved searches...", text: $searchText)
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
    .padding(.vertical, 7)
    .background(Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }

  private func toggle(_ id: UUID) {
    guard !shownIds.contains(id) else { return }
    if ticked.contains(id) {
      ticked.remove(id)
    } else {
      ticked.insert(id)
    }
  }
}

/// A saved search to tick in the Add Saved Searches list
struct macosDashboardAddSearchRow: View {
  var search: SavedSearch
  var dataViewName: String?
  /// Already on the dashboard, so it can't be ticked
  var isShown: Bool
  var isChecked: Bool
  var onToggle: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: onToggle) {
      HStack(spacing: 8) {
        macosSavedCheckbox(isChecked: isChecked, isHovered: isHovered && !isShown)

        VStack(alignment: .leading, spacing: 2) {
          Text(search.displayTitle)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .truncationMode(.middle)
          Text([dataViewName ?? search.searchIndex, search.periodTitle].compactMap { $0 }.joined(separator: " · "))
            .font(.system(size: 11))
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
            .truncationMode(.middle)
        }

        Spacer()

        if isShown {
          Text("On dashboard")
            .font(.system(size: 11))
            .foregroundColor(Color("TextSecondary"))
        }
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(!isShown && (isHovered || isChecked) ? Color("ButtonHighlighted") : Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
      .opacity(isShown ? 0.6 : 1)
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isShown)
    .onHover { isHovered = $0 }
    .accessibilityAddTraits(isChecked ? .isSelected : [])
  }
}
#endif
