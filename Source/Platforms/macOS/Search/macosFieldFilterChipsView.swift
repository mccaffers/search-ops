// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
/// What the user asked a field filter chip to do.
enum FieldFilterChipAction {
  case toggleNegated(UUID)
  case toggleDisabled(UUID)
  case remove(UUID)
  case clearAll
}

/// The field filters under the search box, wrapping onto more lines when they don't fit.
struct macosFieldFilterChipsView: View {
  let filters: [FieldFilter]
  /// The data view's field labels
  var labels: [String: String] = [:]
  let onAction: (FieldFilterChipAction) -> Void

  var body: some View {
    WrappingHStack(horizontalSpacing: 6, verticalSpacing: 6) {
      ForEach(filters) { filter in
        macosFieldFilterChip(filter: filter,
                             label: DataViewSelection.label(for: filter.field, labels: labels),
                             onAction: onAction)
      }
      if filters.count > 1 {
        macosFieldFilterClearAllButton { onAction(.clearAll) }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// One filter: click it for its actions, or delete it with its cross. The actions open in a popover
/// rather than a `Menu`, whose label macOS draws as a pop-up button title and cuts to its first text.
struct macosFieldFilterChip: View {
  let filter: FieldFilter
  /// The data view's label for the field, shown instead of its path
  let label: String?
  let onAction: (FieldFilterChipAction) -> Void
  @State private var isHovered = false
  @State private var isHoveringRemove = false
  @State private var showingActions = false

  private var fieldName: String { label ?? filter.field }

  private var description: String {
    "\(filter.negated ? "NOT " : "")\(fieldName): \(filter.value)\(filter.disabled ? " (disabled)" : "")"
  }

  /// One Text, so it lays out and truncates as a single line
  private var title: Text {
    let field = Text("\(fieldName): ").foregroundColor(Color("LabelBackgroundFocus"))
    let value = Text(FieldFilter.shortened(filter.value)).foregroundColor(Color("TextColor"))
    let text = filter.negated
      ? Text("NOT ").foregroundColor(Color("RedIcon")).fontWeight(.semibold) + field + value
      : field + value
    return text.strikethrough(filter.disabled)
  }

  var body: some View {
    HStack(spacing: 4) {
      Button {
        showingActions.toggle()
      } label: {
        title
          .font(.system(size: 12))
          .lineLimit(1)
          .fixedSize()
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .popover(isPresented: $showingActions, arrowEdge: .bottom) {
        macosFieldFilterChipActions(filter: filter, onCopy: {
          showingActions = false
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(filter.value, forType: .string)
        }, onAction: { action in
          showingActions = false
          onAction(action)
        })
      }

      Button {
        onAction(.remove(filter.id))
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 9, weight: .semibold))
          .foregroundColor(isHoveringRemove ? Color("RedIcon") : Color("TextSecondary"))
          .frame(width: 14, height: 14)
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .help("Remove filter")
      .accessibilityLabel("Remove filter \(description)")
      .onHover { hovering in
        isHoveringRemove = hovering
      }
    }
    .padding(.leading, 8)
    .padding(.trailing, 5)
    .padding(.vertical, 4)
    .background(isHovered || showingActions ? Color("ButtonHighlighted") : Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .opacity(filter.disabled ? 0.55 : 1)
    .help("\(filter.negated ? "NOT " : "")\(filter.field): \(filter.value)")
    .accessibilityElement(children: .contain)
    .accessibilityLabel(description)
    .onHover { hovering in
      isHovered = hovering
      if hovering {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
    // Removing a chip from under the pointer doesn't end its hover, so the cursor is put back here
    .onDisappear {
      if isHovered {
        NSCursor.pop()
      }
    }
  }
}

/// A chip's actions: copy its value, exclude or include it, disable or re-enable it, or delete it.
struct macosFieldFilterChipActions: View {
  let filter: FieldFilter
  let onCopy: () -> Void
  let onAction: (FieldFilterChipAction) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      macosPopoverActionRow(title: "Copy value", systemImage: "doc.on.doc", action: onCopy)
      macosPopoverActionRow(title: filter.negated ? "Include results" : "Exclude results",
                            systemImage: filter.negated ? "plus.magnifyingglass" : "minus.magnifyingglass") {
        onAction(.toggleNegated(filter.id))
      }
      macosPopoverActionRow(title: filter.disabled ? "Re-enable" : "Temporarily disable",
                            systemImage: filter.disabled ? "eye" : "eye.slash") {
        onAction(.toggleDisabled(filter.id))
      }
      Divider()
        .padding(.vertical, 2)
      macosPopoverActionRow(title: "Delete", systemImage: "trash", isDestructive: true) {
        onAction(.remove(filter.id))
      }
    }
    .padding(6)
    .frame(width: 200, alignment: .leading)
    .background(Color("BackgroundAlt"))
  }
}

struct macosFieldFilterClearAllButton: View {
  let action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      Text("Clear all")
        .font(.system(size: 12))
        .foregroundColor(isHovered ? Color("TextColor") : Color("TextSecondary"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovered ? Color("Button") : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .help("Remove all filters")
    .onHover { hovering in
      isHovered = hovering
      if hovering {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
    // Removing a chip from under the pointer doesn't end its hover, so the cursor is put back here
    .onDisappear {
      if isHovered {
        NSCursor.pop()
      }
    }
  }
}
#endif
