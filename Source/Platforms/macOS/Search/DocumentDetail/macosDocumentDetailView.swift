// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import OrderedCollections

#if os(macOS)
public enum macosDocumentView {
  case JSON
  case Document
}

public enum DocumentCheckboxState {
  case off
  case on
  /// Some, but not all, of a group is ticked.
  case mixed
}

/// Checkbox that shows or hides fields in the results list: an empty square, a filled square with a tick,
/// or a filled square with a dash when only some of a group are shown.
struct DocumentCheckboxButton: View {
  let state: DocumentCheckboxState
  let help: String
  let accessibilityLabel: String
  let onToggle: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: onToggle) {
      Group {
        if state == .off {
          Image(systemName: "square")
            .foregroundColor(isHovered ? Color("LabelBackgroundFocus") : Color("TextSecondary"))
        } else {
          // Mark in the text colour on the navy used for selected fields in the sidebar list
          Image(systemName: state == .on ? "checkmark.square.fill" : "minus.square.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(Color("TextColor"), Color("BackgroundAlt3"))
        }
      }
      .font(.system(size: 14))
      .frame(width: 16, height: 16)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .help(help)
    .accessibilityLabel(accessibilityLabel)
    .onHover { hovering in
      isHovered = hovering
      if hovering {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
  }
}

struct DocumentFieldHeaderView: View {
  let key: String
  let type: String?
  /// The data view's label for the field, shown with the path underneath
  var label: String? = nil

  var body: some View {
    HStack(alignment: .center, spacing: 6) {
      if let label = label {
        VStack(alignment: .leading, spacing: 1) {
          Text(label)
            .foregroundColor(Color("LabelBackgroundFocus"))
            .lineLimit(1)
            .truncationMode(.tail)
          Text(key)
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
            .truncationMode(.middle)
        }
        .help("\(label)\n\(key)")
      } else {
        Text(key)
          .foregroundColor(Color("LabelBackgroundFocus"))
          .lineLimit(1)
          .truncationMode(.middle)
          .help(key)
      }

      if let type = type {
        macosFieldTypeBadgeView(type: type)
          .fixedSize()
          .help("Mapped as \(type)")
      }
    }
  }
}

struct DocumentFilterField: View {
  @Binding var text: String
  var isFocused: FocusState<Bool>.Binding
  let matchCount: Int
  let totalCount: Int

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(Color("TextSecondary"))
        .font(.system(size: 11))

      TextField("Filter fields or values...", text: $text)
        .textFieldStyle(PlainTextFieldStyle())
        .font(.system(size: 13))
        .disableAutocorrection(true)
        .focused(isFocused)

      if !text.isEmpty {
        Text("\(matchCount) of \(totalCount)")
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
          .monospacedDigit()

        Button(action: {
          text = ""
        }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(Color("TextSecondary"))
            .font(.system(size: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .help("Clear filter")
        .accessibilityLabel("Clear filter")
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(Color("Background"))
    .clipShape(.rect(cornerRadius: 5))
  }
}

/// A field's value, with buttons to copy it and to filter the search for or against it. They show while the
/// pointer is over the value; the filter buttons also stay when the search already filters on it.
struct DocumentValueCell: View {
  let displayValue: String
  /// The value to filter on, nil when the field has no single value
  let filterValue: String?
  /// Whether the search filters on this value: false keeping it, true excluding it, nil not at all
  let activeFilter: Bool?
  let onFilter: ((_ value: String, _ negated: Bool) -> Void)?
  @State private var isHovered = false
  @State private var copied = false

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Text(displayValue)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)

      // A value already filtered on always shows its filter buttons, so they take their own space
      if activeFilter != nil {
        actionButtons
      }
    }
    // Otherwise they show over the end of the value on hover, so the value can use the column's full width
    // and doesn't reflow as the pointer moves
    .overlay(alignment: .topTrailing) {
      if activeFilter == nil && isHovered {
        actionButtons
          .padding(.leading, 4)
          .background(Color("BackgroundAlt"))
      }
    }
    .contentShape(Rectangle())
    .onHover { hovering in
      isHovered = hovering
      if !hovering {
        copied = false
      }
    }
  }

  private var actionButtons: some View {
    HStack(spacing: 2) {
      DocumentFilterButton(systemImage: copied ? "checkmark" : "doc.on.doc",
                           isActive: copied,
                           help: copied ? "Copied" : "Copy value",
                           accessibilityLabel: "Copy \(displayValue)") {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(filterValue ?? displayValue, forType: .string)
        copied = true
      }
      .opacity(isHovered ? 1 : 0)

      if let filterValue = filterValue, let onFilter = onFilter {
        DocumentFilterButton(systemImage: "plus.magnifyingglass",
                             isActive: activeFilter == false,
                             help: activeFilter == false ? "Already filtering for this value" : "Filter for value",
                             accessibilityLabel: "Filter for \(displayValue)") {
          onFilter(filterValue, false)
        }
        DocumentFilterButton(systemImage: "minus.magnifyingglass",
                             isActive: activeFilter == true,
                             help: activeFilter == true ? "Already filtering out this value" : "Filter out value",
                             accessibilityLabel: "Filter out \(displayValue)") {
          onFilter(filterValue, true)
        }
      }
    }
  }
}

/// A text button in the Document panel's header, lighter on hover
struct DocumentHeaderButton: View {
  var systemImage: String? = nil
  let title: String
  var help: String? = nil
  let action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 5) {
        if let systemImage = systemImage {
          Image(systemName: systemImage)
            .foregroundColor(Color("LabelBackgroundFocus"))
        }
        Text(title)
      }
      .padding(10)
      .background(isHovered ? Color("ButtonHighlighted") : Color("Background"))
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .help(help ?? title)
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

struct DocumentFilterButton: View {
  let systemImage: String
  let isActive: Bool
  let help: String
  let accessibilityLabel: String
  let action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.system(size: 12))
        .foregroundColor(isActive || isHovered ? Color("LabelBackgroundFocus") : Color("TextSecondary"))
        .frame(width: 20, height: 18)
        .background(isHovered ? Color("Button") : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .help(help)
    .accessibilityLabel(accessibilityLabel)
    .onHover { hovering in
      isHovered = hovering
      if hovering {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
    // The panel closes on click, which ends the hover without telling this button
    .onDisappear {
      if isHovered {
        NSCursor.pop()
      }
    }
  }
}

/// The document's fields as a two-column grid: results-list checkbox, field name and type badge | value.
struct DocumentFieldsGrid: View {
  let document: OrderedDictionary<String, Any>
  let keys: [String]
  let fieldType: (String) -> String?
  let isFieldVisible: (String) -> Bool
  let onToggle: (String) -> Void
  /// Whether all, some or none of `keys` are shown in the results list.
  let selectAllState: DocumentCheckboxState
  let onToggleAll: () -> Void
  /// Changes whenever a field is shown or hidden. Visibility lives on the field objects, so this is what tells
  /// SwiftUI the checkboxes need redrawing.
  let fieldsVersion: UUID
  /// The data view's field labels
  var labels: [String: String] = [:]
  /// The search's field filters, to mark the values already filtered on
  var fieldFilters: [FieldFilter] = []
  /// Filters the search for a field's value, or against it when negated. No filter buttons without it.
  var onFilter: ((_ field: String, _ value: String, _ negated: Bool) -> Void)? = nil
  /// Whether each field has a checkbox to show or hide it in the results list
  var showsFieldVisibility: Bool = true
  /// The Field column's width, checkbox included
  var fieldColumnWidth: CGFloat = DocumentFieldsGrid.defaultFieldColumnWidth
  /// Called with the drag distance while the column divider is dragged. No divider handle without it.
  var onFieldColumnDrag: ((_ translation: CGFloat) -> Void)? = nil
  var onFieldColumnDragEnd: () -> Void = {}
  /// Called when the column divider is double-clicked
  var onFieldColumnReset: () -> Void = {}

  private let rowPadding: CGFloat = 6
  private let toggleSpacing: CGFloat = 8

  public static let defaultFieldColumnWidth: CGFloat = 264
  /// Room for the checkbox, a short field name and its type badge
  public static let minFieldColumnWidth: CGFloat = 140
  /// The Value column stays at least this wide beside the Field column
  public static let minValueColumnWidth: CGFloat = 120
  static let columnSpacing: CGFloat = 16
  /// The grid's horizontal padding inside the Document panel, both sides together
  static let panelHorizontalPadding: CGFloat = 30

  /// Keeps the Field column between its minimum and the width that leaves the Value column its minimum.
  /// The minimum wins when the panel is too narrow for both.
  public static func clampedFieldColumnWidth(_ width: CGFloat, panelWidth: CGFloat) -> CGFloat {
    let maxWidth = panelWidth - panelHorizontalPadding - columnSpacing - minValueColumnWidth
    return max(minFieldColumnWidth, min(width, maxWidth))
  }

  /// The Field column width after dragging the column divider by `translation`: right widens it, left narrows it.
  public static func resizedFieldColumnWidth(start: CGFloat, translation: CGFloat, panelWidth: CGFloat) -> CGFloat {
    clampedFieldColumnWidth(start + translation, panelWidth: panelWidth)
  }

  /// For example "48 fields · 12 selected", or "1 field" when none are selected.
  static func countLabel(total: Int, selected: Int) -> String {
    let fields = "\(total) \(total == 1 ? "field" : "fields")"
    return selected > 0 ? "\(fields) · \(selected) selected" : fields
  }

  var body: some View {
    let active = fieldFilters.enabledValues
    Grid(alignment: .topLeading, horizontalSpacing: DocumentFieldsGrid.columnSpacing, verticalSpacing: 0) {
      GridRow(alignment: .center) {
        HStack(alignment: .center, spacing: toggleSpacing) {
          if showsFieldVisibility {
            DocumentCheckboxButton(
              state: selectAllState,
              help: selectAllState == .on
                ? "Hide these fields from results list"
                : "Show these fields in results list",
              accessibilityLabel: selectAllState == .on
                ? "Hide all \(keys.count) fields from results list"
                : "Show all \(keys.count) fields in results list",
              onToggle: onToggleAll
            )
          }
          Text("Field")
            .fixedSize()
          Text(DocumentFieldsGrid.countLabel(total: keys.count, selected: keys.filter(isFieldVisible).count))
            .font(.system(size: 11))
            .opacity(0.7)
            .lineLimit(1)
        }
        .frame(width: fieldColumnWidth, alignment: .leading)
        Text("Value")
      }
      .font(.system(size: 11, weight: .medium))
      .foregroundColor(Color("TextSecondary"))
      .padding(.bottom, rowPadding)

      Divider()

      ForEach(keys, id: \.self) { key in
        if let rawValue = document[key],
           let displayValue = DocumentDetail.formatDisplayValue(rawValue) {
          GridRow {
            // The checkbox leads each field cell, so the checkboxes line up down the left edge.
            HStack(alignment: .center, spacing: toggleSpacing) {
              if showsFieldVisibility {
                DocumentCheckboxButton(
                  state: isFieldVisible(key) ? .on : .off,
                  help: isFieldVisible(key) ? "Hide field from results list" : "Show field in results list",
                  accessibilityLabel: isFieldVisible(key)
                    ? "Hide \(key) from results list"
                    : "Show \(key) in results list",
                  onToggle: { onToggle(key) }
                )
              }
              DocumentFieldHeaderView(key: key,
                                      type: fieldType(key),
                                      label: DataViewSelection.label(for: key, labels: labels))
            }
            .frame(width: fieldColumnWidth, alignment: .leading)
            .padding(.vertical, rowPadding)

            let filterValue = FieldFilter.make(field: key, values: rawValue)?.value
            DocumentValueCell(
              displayValue: displayValue,
              filterValue: filterValue,
              activeFilter: filterValue.flatMap { active[FieldFilterKey(field: key, value: $0)] },
              onFilter: onFilter.map { onFilter in { value, negated in onFilter(key, value, negated) } }
            )
            .padding(.vertical, rowPadding)
          }

          Divider()
            .opacity(0.5)
        }
      }
    }
    // Runs the grid's full height in the gap between the columns
    .overlay(alignment: .topLeading) {
      if let onFieldColumnDrag = onFieldColumnDrag {
        DocumentColumnResizeHandle(onDrag: onFieldColumnDrag,
                                   onDragEnd: onFieldColumnDragEnd,
                                   onDoubleClick: onFieldColumnReset)
          .offset(x: fieldColumnWidth + (DocumentFieldsGrid.columnSpacing - DocumentColumnResizeHandle.width) / 2)
      }
    }
  }
}

/// The grab area between the Document panel's Field and Value columns, with a hairline that brightens on hover or drag.
/// Dragging resizes the Field column and double-clicking puts it back to its default width.
struct DocumentColumnResizeHandle: View {
  static let width: CGFloat = 9

  let onDrag: (_ translation: CGFloat) -> Void
  let onDragEnd: () -> Void
  let onDoubleClick: () -> Void
  @State private var isActive = false

  var body: some View {
    ZStack {
      Rectangle()
        .fill(isActive ? Color("LabelBackgroundFocus") : Color("TextSecondary").opacity(0.25))
        .frame(width: isActive ? 2 : 1)
        .allowsHitTesting(false)

      macosSidebarResizeHandle(onDrag: onDrag,
                               onDragEnd: onDragEnd,
                               onActiveChanged: { isActive = $0 },
                               onDoubleClick: onDoubleClick)
    }
    .frame(width: Self.width)
    .frame(maxHeight: .infinity)
    .help("Drag to resize the Field column. Double-click to reset it.")
    .accessibilityLabel("Resize Field column")
  }
}

/// The grab area on the Document panel's left edge, with a small bar that brightens on hover or drag.
/// Dragging resizes the panel and double-clicking puts it back to half the search area.
struct macosDocumentPanelResizeHandle: View {
  static let width: CGFloat = 9

  let onDrag: (_ translation: CGFloat) -> Void
  let onDragEnd: () -> Void
  let onDoubleClick: () -> Void
  @State private var isActive = false

  var body: some View {
    ZStack {
      Capsule()
        .fill(isActive ? Color("LabelBackgroundFocus") : Color("TextSecondary").opacity(0.6))
        .frame(width: 4, height: 72)
        .allowsHitTesting(false)

      macosSidebarResizeHandle(onDrag: onDrag,
                               onDragEnd: onDragEnd,
                               onActiveChanged: { isActive = $0 },
                               onDoubleClick: onDoubleClick)
    }
    .frame(width: Self.width)
    .help("Drag to resize the panel. Double-click to reset it to half width.")
    .accessibilityLabel("Resize Document panel")
  }
}

/// Calls `onEscape` when Escape is pressed in the window holding this view, swallowing the key when it returns true.
/// Unlike `onExitCommand`, it works wherever focus is in the window, or when nothing has focus.
struct macosEscapeKeyMonitor: NSViewRepresentable {
  let onEscape: () -> Bool

  func makeNSView(context: Context) -> MonitorView {
    let view = MonitorView()
    view.onEscape = onEscape
    return view
  }

  func updateNSView(_ nsView: MonitorView, context: Context) {
    nsView.onEscape = onEscape
  }

  final class MonitorView: NSView {
    var onEscape: () -> Bool = { false }
    private var monitor: Any?

    // Only listens while in a window, so the monitor goes when the view does
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      removeMonitor()
      guard window != nil else { return }
      monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        // Leave Escape to other windows, and to a sheet over this one
        guard let self = self,
              event.keyCode == 53,
              event.window === self.window,
              event.window?.attachedSheet == nil,
              self.onEscape() else { return event }
        return nil
      }
    }

    deinit {
      removeMonitor()
    }

    private func removeMonitor() {
      if let monitor = monitor {
        NSEvent.removeMonitor(monitor)
      }
      monitor = nil
    }
  }
}

struct macosDocumentDetailView: View {
  
  @ObservedObject var itemDetail: DocumentDetail
  @Binding var fields: [SquashedFieldsArray]
  @Binding var onlyVisibleFields: [SquashedFieldsArray]
  @Binding var updatedFieldsNotification: UUID
  /// The data view's field labels
  var labels: [String: String] = [:]
  /// The panel's width, not counting its margin from the window edge
  var width: CGFloat = 600
  /// The search area's width, which limits how wide a drag can make the panel
  var availableWidth: CGFloat = 1200
  /// Called with the new width when a resize drag ends
  var onResized: (CGFloat) -> Void = { _ in }
  /// Called when the edge is double-clicked
  var onResetWidth: () -> Void = {}
  /// The search's field filters, to mark the values already filtered on
  var fieldFilters: [FieldFilter] = []
  /// Filters the search for a field's value, or against it when negated
  var onFilter: ((_ field: String, _ value: String, _ negated: Bool) -> Void)? = nil
  /// Closes the panel, when Escape is pressed with nothing typed in the filter
  var onClose: () -> Void = {}
  /// Whether the document is in the Saved tab. No Save button when nil, eg. a document without an id.
  var isSaved: Bool? = nil
  var onToggleSaved: () -> Void = {}
  /// Whether each field has a checkbox to show or hide it in the results list
  var showsFieldVisibility: Bool = true
  /// The gap above the panel, leaving room for the bar it opens under
  var topPadding: CGFloat = 36
  /// The width while the edge is being dragged, so only this panel redraws until the drag ends
  @State private var dragWidth: CGFloat? = nil
  @AppStorage("macosDocumentFieldColumnWidth") private var fieldColumnWidth: Double = DocumentFieldsGrid.defaultFieldColumnWidth
  /// The Field column width while its divider is being dragged, saved when the drag ends
  @State private var fieldColumnDragWidth: CGFloat? = nil
  @State private var slidIn = false
  @State private var view : macosDocumentView = .Document
  @State private var jsonDocument = ""
  @State private var filterText = ""
  @FocusState private var filterFocused: Bool
  
  func isFieldVisible(_ key: String) -> Bool {
    Self.isFieldVisible(key, in: fields, onlyVisibleFields: onlyVisibleFields)
  }

  func fieldType(_ key: String) -> String? {
    Self.fieldType(key, in: fields, onlyVisibleFields: onlyVisibleFields)
  }

  func toggleFieldVisibility(_ key: String) {
    _ = Self.toggleFieldVisibility(key, fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    updatedFieldsNotification = UUID()
  }

  func toggleAllFieldsVisibility(_ keys: [String]) {
    Self.toggleAllFieldsVisibility(keys, fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    updatedFieldsNotification = UUID()
  }

  /// The panel's width, following its edge while that's dragged
  var panelWidth: CGFloat { dragWidth ?? width }

  func containsCharacters(_ values: [String]) -> Bool {
      let joinedString = values.joined()
      return !joinedString.isEmpty
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let document = itemDetail.item {
        
        HStack(alignment: .center) {
          Group {
            if view == .Document {
              Text("Document")
            } else {
              Text("JSON")
            }
          }
            .font(.system(size: 18))
            .padding(.leading, 15)
          
          Spacer()
          
          if let isSaved = isSaved {
            DocumentHeaderButton(systemImage: isSaved ? "bookmark.fill" : "bookmark",
                                 title: isSaved ? "Saved" : "Save",
                                 help: isSaved ? "Remove from Saved" : "Keep this document in the Saved tab",
                                 action: onToggleSaved)
          }
          
          DocumentHeaderButton(title: view == .Document ? "View as JSON" : "View as Document") {
            if view == .Document {
              view = .JSON
            } else {
              view = .Document
            }
          }
          .padding(.trailing, 10)
          
        }
        .padding(.vertical, 5)
        .background(Color("Button"))
        
        
        if view == .Document {
          let keys = DocumentDetail.filteredKeys(document, matching: filterText)
          
          DocumentFilterField(
            text: $filterText,
            isFocused: $filterFocused,
            matchCount: keys.count,
            totalCount: DocumentDetail.filteredKeys(document, matching: "").count
          )
          .padding(.horizontal, 15)
          .padding(.top, 10)
          
          ScrollView {
            VStack(alignment: .leading, spacing:0) {
              let trimmedFilter = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
              if keys.isEmpty && !trimmedFilter.isEmpty {
                Text("No fields match \"\(trimmedFilter)\"")
                  .foregroundColor(Color("TextSecondary"))
              }
              if !keys.isEmpty {
                DocumentFieldsGrid(
                  document: document,
                  keys: keys,
                  fieldType: fieldType,
                  isFieldVisible: isFieldVisible,
                  onToggle: toggleFieldVisibility,
                  selectAllState: Self.selectionState(of: keys, in: fields, onlyVisibleFields: onlyVisibleFields),
                  onToggleAll: { toggleAllFieldsVisibility(keys) },
                  fieldsVersion: updatedFieldsNotification,
                  labels: labels,
                  fieldFilters: fieldFilters,
                  onFilter: onFilter,
                  showsFieldVisibility: showsFieldVisibility,
                  fieldColumnWidth: DocumentFieldsGrid.clampedFieldColumnWidth(fieldColumnDragWidth ?? fieldColumnWidth,
                                                                               panelWidth: panelWidth),
                  onFieldColumnDrag: { translation in
                    // Measured from the width shown before the drag, which may be narrower than the saved one
                    let start = DocumentFieldsGrid.clampedFieldColumnWidth(fieldColumnWidth, panelWidth: panelWidth)
                    fieldColumnDragWidth = DocumentFieldsGrid.resizedFieldColumnWidth(start: start,
                                                                                      translation: translation,
                                                                                      panelWidth: panelWidth)
                  },
                  onFieldColumnDragEnd: {
                    if let fieldColumnDragWidth = fieldColumnDragWidth {
                      fieldColumnWidth = fieldColumnDragWidth
                    }
                    fieldColumnDragWidth = nil
                  },
                  onFieldColumnReset: {
                    fieldColumnWidth = DocumentFieldsGrid.defaultFieldColumnWidth
                  }
                )
              }
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            
          }
        } else if view == .JSON {
          BetterTextEditor(text: .constant(jsonDocument), onClick:{})
          .textFieldStyle(PlainTextFieldStyle())
          .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
          .font(.system(size: 18))
          .frame(maxHeight: .infinity)
          .onAppear {
            jsonDocument = itemDetail.asJson()
          }
          
        }
      }
    }
    .textSelection(.enabled)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("BackgroundAlt"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    // Sits across the left edge, outside the clip so its bar isn't cut in half
    .overlay(alignment: .leading) {
      macosDocumentPanelResizeHandle(
        onDrag: { translation in
          dragWidth = macosSearchMainView.resizedDocumentPanelWidth(start: width,
                                                                   translation: translation,
                                                                   available: availableWidth)
        },
        onDragEnd: {
          if let dragWidth = dragWidth {
            onResized(dragWidth)
          }
          dragWidth = nil
        },
        onDoubleClick: onResetWidth
      )
      .offset(x: -macosDocumentPanelResizeHandle.width / 2)
    }
    .padding(.bottom, 25)
    .frame(width: dragWidth ?? width)
    .padding(.trailing, 10)
    .padding(.top, topPadding)
    // Starts a full panel width to the right, so it slides in from off screen however wide it is
    .offset(x: slidIn ? 0 : (dragWidth ?? width) + 10)
    .animation(.spring(response: 0.25, dampingFraction: 1, blendDuration: 0), value: slidIn)
    .background(
      // Escape clears the filter first, then closes the panel
      macosEscapeKeyMonitor {
        if !filterText.isEmpty {
          filterText = ""
        } else {
          onClose()
        }
        return true
      }
    )
    .onAppear {
      slidIn = true
      filterFocused = true
    }
    .onDisappear {
      itemDetail.showingView = false
      itemDetail.item = nil
      itemDetail.ref = nil
    }
  }
}

extension macosDocumentDetailView {
  public static func isFieldVisible(
    _ key: String,
    in fields: [SquashedFieldsArray],
    onlyVisibleFields: [SquashedFieldsArray] = []
  ) -> Bool {
    if let field = fields.first(where: { $0.squashedString == key }) {
      return field.visible
    }
    return onlyVisibleFields.first(where: { $0.squashedString == key })?.visible ?? false
  }

  /// The field's mapping type, such as `float` or `keyword`, or nil when the field isn't in the mapping.
  public static func fieldType(
    _ key: String,
    in fields: [SquashedFieldsArray],
    onlyVisibleFields: [SquashedFieldsArray] = []
  ) -> String? {
    (fields + onlyVisibleFields)
      .first(where: { $0.squashedString == key && !$0.type.isEmpty })?
      .type
  }

  /// `.on` when every key is shown in the results list, `.off` when none are (or there are no keys), else `.mixed`.
  public static func selectionState(
    of keys: [String],
    in fields: [SquashedFieldsArray],
    onlyVisibleFields: [SquashedFieldsArray] = []
  ) -> DocumentCheckboxState {
    let visibleCount = keys.filter { isFieldVisible($0, in: fields, onlyVisibleFields: onlyVisibleFields) }.count
    if visibleCount == 0 { return .off }
    return visibleCount == keys.count ? .on : .mixed
  }

  /// Shows every key in the results list when any of them is hidden, otherwise hides them all.
  /// Returns the visibility the keys now have.
  @discardableResult
  public static func toggleAllFieldsVisibility(
    _ keys: [String],
    fields: inout [SquashedFieldsArray],
    onlyVisibleFields: inout [SquashedFieldsArray]
  ) -> Bool {
    // Look each key up once rather than searching both lists for every key
    var fieldsByKey = firstByKey(fields)
    var visibleByKey = firstByKey(onlyVisibleFields)
    func isVisible(_ key: String) -> Bool {
      (fieldsByKey[key] ?? visibleByKey[key])?.visible ?? false
    }

    let visibleCount = keys.filter(isVisible).count
    let newVisible = !(visibleCount > 0 && visibleCount == keys.count)
    for key in keys where isVisible(key) != newVisible {
      let field = setFieldVisibility(key,
                                     visible: newVisible,
                                     inFields: fieldsByKey[key],
                                     inVisible: visibleByKey[key],
                                     fields: &fields,
                                     onlyVisibleFields: &onlyVisibleFields)
      fieldsByKey[key] = fieldsByKey[key] ?? field
      if newVisible {
        visibleByKey[key] = visibleByKey[key] ?? field
      }
    }
    return newVisible
  }

  @discardableResult
  public static func toggleFieldVisibility(
    _ key: String,
    fields: inout [SquashedFieldsArray],
    onlyVisibleFields: inout [SquashedFieldsArray]
  ) -> Bool {
    let inFields = fields.first(where: { $0.squashedString == key })
    let inVisible = onlyVisibleFields.first(where: { $0.squashedString == key })
    // A key in neither list isn't shown yet, so toggling it shows it
    let newVisible = !((inFields ?? inVisible)?.visible ?? false)
    setFieldVisibility(key,
                       visible: newVisible,
                       inFields: inFields,
                       inVisible: inVisible,
                       fields: &fields,
                       onlyVisibleFields: &onlyVisibleFields)
    return newVisible
  }

  /// Shows or hides the key in both lists, adding it to `fields` when it isn't mapped and to `onlyVisibleFields`
  /// when it's newly shown. Each field's `visible` is only set when it changes, so its observers hear once.
  /// Returns the field now in `fields` for the key.
  @discardableResult
  private static func setFieldVisibility(
    _ key: String,
    visible: Bool,
    inFields: SquashedFieldsArray?,
    inVisible: SquashedFieldsArray?,
    fields: inout [SquashedFieldsArray],
    onlyVisibleFields: inout [SquashedFieldsArray]
  ) -> SquashedFieldsArray {
    let field: SquashedFieldsArray
    if let inFields = inFields {
      field = inFields
    } else {
      field = inVisible ?? SquashedFieldsArray(squashedString: key, fieldParts: key.components(separatedBy: "."))
      fields.append(field)
    }
    setVisible(field, visible)

    if let inVisible = inVisible {
      if inVisible !== field {
        setVisible(inVisible, visible)
      }
    } else if visible {
      onlyVisibleFields.append(field)
    }
    return field
  }

  private static func setVisible(_ field: SquashedFieldsArray, _ visible: Bool) {
    if field.visible != visible {
      field.visible = visible
    }
  }

  /// The first field for each key, as `first(where:)` would find it.
  private static func firstByKey(_ fields: [SquashedFieldsArray]) -> [String: SquashedFieldsArray] {
    Dictionary(fields.map { ($0.squashedString, $0) }, uniquingKeysWith: { first, _ in first })
  }
}

#endif
