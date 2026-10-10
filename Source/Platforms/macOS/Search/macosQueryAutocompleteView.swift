// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

/// Suggestions for the word being typed in the search box: field names, then after `field:`
/// the field's most recent values, which are loaded from the server once per field and time period
@MainActor
final class macosQueryAutocompleteModel: ObservableObject {
  @Published private(set) var suggestions = [QueryAutocompleteSuggestion]()
  /// Nil until the arrow keys pick a row, so Return still searches
  @Published private(set) var highlightedIndex: Int?
  /// Set while a field's values are loading, the list shows a loading row
  @Published private(set) var isLoadingValues = false
  private var token: QueryAutocompleteToken?
  /// Set while the pointer is over the list, so clicking a row doesn't hide it first
  var pointerInside = false

  static let valuesLifetime: TimeInterval = 60
  private var valueCache = [String: (values: [String], loaded: Date)]()
  /// The scope and field being loaded, so a slower earlier load doesn't replace a newer one
  private var loadingKey: String?
  private var lastEdit: (text: String, cursor: Int, scope: String)?

  var isVisible: Bool { !suggestions.isEmpty || isLoadingValues }

  /// Called as the query is edited. Typing opens the list; moving the cursor only updates or closes
  /// it, unless the cursor lands straight after `field:`. `scope` names the host, index and time
  /// period that `loadValues` reads values from.
  func update(text: String, cursor: Int?, textChanged: Bool,
              fields: [SquashedFieldsArray], labels: [String: String],
              scope: String, loadValues: @escaping (String) async -> [String]) {
    let context = cursor.flatMap { QueryAutocomplete.context(in: text, cursor: $0) }
    if !textChanged && !isVisible {
      guard case .value(_, let token)? = context, token.prefix.isEmpty else { return }
    }
    guard let cursor = cursor, let context = context else {
      dismiss()
      return
    }
    lastEdit = (text, cursor, scope)

    switch context {
    case .field(let token):
      isLoadingValues = false
      show(QueryAutocomplete.suggestions(for: token.prefix, fields: fields, labels: labels), token: token)

    case .value(let field, let token):
      let key = scope + "|" + field
      if let cached = valueCache[key], Date().timeIntervalSince(cached.loaded) < Self.valuesLifetime {
        isLoadingValues = false
        show(QueryAutocomplete.valueSuggestions(for: token.prefix, values: cached.values), token: token)
        return
      }
      self.token = token
      suggestions = []
      highlightedIndex = nil
      isLoadingValues = true
      if loadingKey != key {
        loadingKey = key
        Task {
          let values = await loadValues(field)
          finishLoading(key: key, values: values)
        }
      }
    }
  }

  private func finishLoading(key: String, values: [String]) {
    valueCache[key] = (values, Date())
    guard loadingKey == key else { return }
    loadingKey = nil
    guard isLoadingValues else { return }
    isLoadingValues = false

    // Show them if the cursor is still on this field's value
    guard let edit = lastEdit,
          case .value(let field, let token)? = QueryAutocomplete.context(in: edit.text, cursor: edit.cursor),
          edit.scope + "|" + field == key else {
      dismiss()
      return
    }
    show(QueryAutocomplete.valueSuggestions(for: token.prefix, values: values), token: token)
  }

  private func show(_ suggestions: [QueryAutocompleteSuggestion], token: QueryAutocompleteToken) {
    guard !suggestions.isEmpty else {
      dismiss()
      return
    }
    if suggestions != self.suggestions {
      highlightedIndex = nil
    }
    self.token = token
    self.suggestions = suggestions
  }

  func moveDown() {
    guard !suggestions.isEmpty else { return }
    highlightedIndex = min((highlightedIndex ?? -1) + 1, suggestions.count - 1)
  }

  func moveUp() {
    guard let index = highlightedIndex else { return }
    highlightedIndex = index > 0 ? index - 1 : nil
  }

  /// The query with the suggestion at `index` filled in, and where the cursor goes. Closes the list.
  func complete(at index: Int, in text: String) -> (text: String, cursor: Int, kind: QueryAutocompleteSuggestion.Kind)? {
    guard let token = token, suggestions.indices.contains(index) else { return nil }
    let suggestion = suggestions[index]
    let result: (text: String, cursor: Int)
    switch suggestion.kind {
    case .field:
      result = QueryAutocomplete.apply(field: suggestion.text, to: text, token: token)
    case .value:
      result = QueryAutocomplete.apply(value: suggestion.text, to: text, token: token)
    }
    dismiss()
    return (result.text, result.cursor, suggestion.kind)
  }

  func dismiss() {
    if !suggestions.isEmpty {
      suggestions = []
    }
    if isLoadingValues {
      isLoadingValues = false
    }
    highlightedIndex = nil
    token = nil
    pointerInside = false
  }
}

/// The search box's bounds, so the suggestions can sit just below it
struct macosQueryFieldBoundsKey: PreferenceKey {
  static var defaultValue: Anchor<CGRect>? = nil

  static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
    value = value ?? nextValue()
  }
}

struct macosQueryAutocompleteView: View {
  @ObservedObject var model: macosQueryAutocompleteModel
  var onSelect: (Int) -> Void

  @State private var hoveredIndex: Int?

  static let rowHeight: CGFloat = 32
  static let maxVisibleRows = 8

  var listHeight: CGFloat {
    let rows = model.isLoadingValues ? 1 : model.suggestions.count
    return CGFloat(min(rows, Self.maxVisibleRows)) * Self.rowHeight + 10
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 0) {
          if model.isLoadingValues {
            HStack(spacing: 8) {
              ProgressView()
                .controlSize(.small)
              Text("Loading values…")
                .font(.system(size: 13))
                .foregroundColor(Color("TextSecondary"))
              Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: Self.rowHeight)
          }
          ForEach(Array(model.suggestions.enumerated()), id: \.element.id) { index, suggestion in
            Button {
              onSelect(index)
            } label: {
              row(suggestion, active: index == model.highlightedIndex || index == hoveredIndex)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
              if hovering {
                hoveredIndex = index
              } else if hoveredIndex == index {
                hoveredIndex = nil
              }
            }
            .id(suggestion.id)
          }
        }
        .padding(5)
      }
      .frame(height: listHeight)
      .onChange(of: model.highlightedIndex) { index in
        if let index = index, model.suggestions.indices.contains(index) {
          proxy.scrollTo(model.suggestions[index].id)
        }
      }
    }
    .background(Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    .onHover { hovering in
      model.pointerInside = hovering
    }
  }

  func row(_ suggestion: QueryAutocompleteSuggestion, active: Bool) -> some View {
    HStack(spacing: 8) {
      Text(suggestion.text)
        .font(.system(size: 13))
        .lineLimit(1)
        .truncationMode(.middle)
      if let label = suggestion.label {
        Text(label)
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
      }
      Spacer(minLength: 8)
      if !suggestion.type.isEmpty {
        macosFieldTypeBadgeView(type: suggestion.type)
      }
    }
    .padding(.horizontal, 8)
    .frame(height: Self.rowHeight)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(active ? Color("ButtonHighlighted") : Color.clear)
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .contentShape(Rectangle())
  }
}

#endif
