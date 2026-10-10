// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

enum FieldListMode: CaseIterable {
  /// Every field mapped in the index.
  case mapped
  /// Fields that appear in the returned documents.
  case inDocuments
  /// Fields toggled on, shown as columns in the results.
  case selected

  var title: String {
    switch self {
    case .mapped: return "All mapped fields"
    case .inDocuments: return "Fields in results"
    case .selected: return "Selected fields"
    }
  }

  var systemImage: String {
    switch self {
    case .mapped: return "list.bullet"
    case .inDocuments: return "wand.and.stars"
    case .selected: return "eye"
    }
  }

  var help: String {
    switch self {
    case .mapped: return "Show all mapped fields in the index"
    case .inDocuments: return "Show only fields in the returned documents"
    case .selected: return "Show only selected fields"
    }
  }

  var emptyMessage: String {
    switch self {
    case .selected: return "No selected fields"
    default: return "No visible fields"
    }
  }
}

struct macosSearchFieldSheetView: View {
  
  @State var loading = false
  
  var selectedIndex: String

  @Binding var fields: [SquashedFieldsArray]

//  @EnvironmentObject var selectedHost: HostDetailsWrap
  
  @Binding var updatedFieldsNotification : UUID
  @Binding var onlyVisibleFields : [SquashedFieldsArray]
  
  var mode: FieldListMode = .mapped
  
  @State var showingMeta = false
  
  @Binding var fieldsSearchtext : String

  /// The column order the user dragged the selected fields into. Fields missing from it follow in mapped order.
  @Binding var fieldOrder: [String]

  /// The active date field. It's always the first column, so the selected list pins it to the top.
  var dateFieldKey: String? = nil
  /// The data view's field labels: shown in the list, and matched by the search
  var labels: [String: String] = [:]

  @discardableResult
  public static func setFieldVisibility(
    item: SquashedFieldsArray,
    visible: Bool,
    fields: [SquashedFieldsArray],
    onlyVisibleFields: [SquashedFieldsArray]
  ) -> Bool {
    guard item.visible != visible else { return false }
    item.visible = visible
    onlyVisibleFields.first(where: { $0.squashedString == item.squashedString })?.visible = visible
    fields.first(where: { $0.squashedString == item.squashedString })?.visible = visible
    return true
  }
  
  func onHide(item: SquashedFieldsArray) {
    if Self.setFieldVisibility(item: item, visible: false, fields: fields, onlyVisibleFields: onlyVisibleFields) {
      updatedFieldsNotification = UUID()
    }
  }
  
  func onAdd(item: SquashedFieldsArray) {
    if Self.setFieldVisibility(item: item, visible: true, fields: fields, onlyVisibleFields: onlyVisibleFields) {
      updatedFieldsNotification = UUID()
    }
  }
  
  /// The selected fields in column order: the pinned date field first, then the keys in `order`,
  /// then any others in the order they come in `selected`.
  static func orderSelectedFields(
    _ selected: [SquashedFieldsArray],
    order: [String],
    pinnedKey: String? = nil
  ) -> [SquashedFieldsArray] {
    let rank = Dictionary(order.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
    let pinned = selected.filter { $0.squashedString == pinnedKey }
    let rest = selected.enumerated()
      .filter { $0.element.squashedString != pinnedKey }
      .sorted {
        (rank[$0.element.squashedString] ?? Int.max, $0.offset) < (rank[$1.element.squashedString] ?? Int.max, $1.offset)
      }
      .map { $0.element }
    return pinned + rest
  }

  /// `keys` with `key` moved into `target`'s place: after it when dragged down, before it when dragged up.
  static func moveField(_ key: String, onto target: String, in keys: [String]) -> [String] {
    guard key != target,
          let from = keys.firstIndex(of: key),
          let to = keys.firstIndex(of: target) else { return keys }
    var output = keys
    output.remove(at: from)
    output.insert(key, at: to)
    return output
  }

  static func filterFields(
    mode: FieldListMode,
    fields: [SquashedFieldsArray],
    onlyVisibleFields: [SquashedFieldsArray],
    searchText: String,
    fieldOrder: [String] = [],
    dateFieldKey: String? = nil,
    labels: [String: String] = [:]
  ) -> [SquashedFieldsArray] {
    let source: [SquashedFieldsArray]
    switch mode {
    case .mapped:
      source = fields
    case .inDocuments:
      source = onlyVisibleFields
    case .selected:
      source = orderSelectedFields(fields.filter { $0.visible }, order: fieldOrder, pinnedKey: dateFieldKey)
    }

    var output = source.filter {
      $0.squashedString.localizedCaseInsensitiveContains(searchText) ||
      (DataViewSelection.label(for: $0.squashedString, labels: labels)?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
    if output.count == 0 {
      output = source
    }

    if mode == .inDocuments {
      output = fields.filter { item in
        output.contains(where: { $0.squashedString == item.squashedString })
      }
    }
    return output
  }

  var filteredFields: [SquashedFieldsArray] {
    Self.filterFields(mode: mode,
                      fields: fields,
                      onlyVisibleFields: onlyVisibleFields,
                      searchText: fieldsSearchtext,
                      fieldOrder: fieldOrder,
                      dateFieldKey: dateFieldKey,
                      labels: labels)
  }

  /// Drops `key` onto `target` in the selected list. Works on the whole selection, so a search filter doesn't lose
  /// the position of the fields it hides.
  func onMove(key: String, target: String) {
    let keys = Self.orderSelectedFields(fields.filter { $0.visible }, order: fieldOrder)
      .map { $0.squashedString }
      .filter { $0 != dateFieldKey }
    fieldOrder = Self.moveField(key, onto: target, in: keys)
  }

  var body: some View {
    
    VStack(alignment:.center, spacing: 0) {

        if loading {
          VStack {
            ProgressView()
            Spacer()
          }.frame(maxWidth: .infinity, alignment: .center)
        } else if filteredFields.count == 0 {
          Text(mode.emptyMessage)
            .padding(.top, 20)
            .foregroundStyle(Color("TextSecondary"))
          Spacer()
        } else {
          
          ScrollView {
            FieldsList(fields: filteredFields,
                       onHide: onHide,
                       onAdd: onAdd,
                       onMove: mode == .selected ? onMove : nil,
                       pinnedKey: dateFieldKey,
                       labels: labels)

          }.scrollIndicators(.never)
          
          Rectangle()
            .fill(Color("macosDivider"))
            .frame(height: 1)
            .padding(.top, 10)
          
    
          
        }
      }
      .onChange(of: selectedIndex) { newValue in
        loading = true
      }
      .onChange(of: fields) { _ in
        loading = false
      }
      .onAppear {
        loading = false
      }
    
    
  }

}
