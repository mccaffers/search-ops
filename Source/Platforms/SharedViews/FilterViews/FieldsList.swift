// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import UniformTypeIdentifiers

struct FieldTypeView: View {
    var type: String

    var body: some View {
        VStack {
            if type == "date" {
              Text("date")
                .font(.system(size: 10))
            } else if type == "text" {
              Text("str")
                .font(.system(size: 11))
            } else {
              Text("#")
                .font(.system(size: 11))
            }
        }
        .frame(width: 24)
        .padding(.vertical, 4)
        .padding(.horizontal, 5)
        .contentShape(Rectangle())
        .background(ColorForType(input: type))
        .background(Color("BackgroundAlt").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    func ColorForType(input: String) -> Color {
        switch input {
        case "date":
          return Color("LabelBackgroundFocus").opacity(0.4)
        case "text":
            return Color("OrangeHighlighted").opacity(0.4)
        default:
            return Color.gray.opacity(0.4)
        }
    }
}

struct FieldButton : View {
  
  @ObservedObject var field: SquashedFieldsArray
  var onHide: (SquashedFieldsArray) -> Void
  var onAdd: (SquashedFieldsArray) -> Void
  var showsDragHandle = false
  /// The data view's label for the field, shown with the path underneath
  var label: String? = nil
  
  @State var isHovering = false
  
  func shouldHighlight() -> Color {
    if field.visible {
      return Color("BackgroundAlt3")
    } else {
      return Color.clear
    }
  }
  var body: some View {
    Button {
      if field.visible {
        onHide(field)
      } else {
        onAdd(field)
      }
    } label: {
      HStack(spacing:4) {
        if showsDragHandle {
          Image(systemName: "line.3.horizontal")
            .font(.system(size: 10))
            .foregroundStyle(Color("TextSecondary"))
            .opacity(isHovering ? 1 : 0.5)
            .padding(.trailing, 2)
        }
        if let label = label {
          VStack(alignment: .leading, spacing: 1) {
            Text(label)
              .font(.system(size: 12, weight: .medium))
            Text(field.squashedString)
              .font(.system(size: 10, design: .monospaced))
              .foregroundStyle(Color("TextSecondary"))
          }
          .padding(.vertical, 6)
          .help(field.squashedString)
        } else {
          Text(field.squashedString)
            .font(.system(size: 12))
            .padding(.vertical, 8)
        }
      
        Spacer()

        Group {
          FieldTypeView(type: field.type)
        }
      }
      .padding(.horizontal, 5)
      .background(isHovering ? Color("BackgroundAlt2") : shouldHighlight())
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
    
    }.buttonStyle(PlainButtonStyle())
    .onHover { hover in
      isHovering = hover
    }
  }
}

/// Moves the dragged field into the hovered row's place as the drag passes over it.
struct FieldReorderDropDelegate: DropDelegate {
  let targetKey: String
  @Binding var draggingKey: String?
  let onMove: (_ key: String, _ target: String) -> Void

  func dropEntered(info: DropInfo) {
    guard let key = draggingKey, key != targetKey else { return }
    withAnimation(.easeInOut(duration: 0.15)) {
      onMove(key, targetKey)
    }
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    DropProposal(operation: .move)
  }

  func performDrop(info: DropInfo) -> Bool {
    draggingKey = nil
    return true
  }
}

struct FieldsList: View {
    var fields: [SquashedFieldsArray]

    var onHide: (SquashedFieldsArray) -> Void
    var onAdd: (SquashedFieldsArray) -> Void
    /// Set to let rows be dragged into a new order. Called with the dragged key and the key of the row it's over.
    var onMove: ((_ key: String, _ target: String) -> Void)? = nil
    /// A row that stays put and can't be dragged or dropped on, such as the date field.
    var pinnedKey: String? = nil
    /// The data view's field labels, shown above the field paths
    var labels: [String: String] = [:]

  @State private var draggingKey: String?

  var body: some View {
    LazyVStack(spacing:0) {
      ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
        let canMove = onMove != nil && field.squashedString != pinnedKey
        VStack(spacing: 0) {
          
          FieldButton(field: field,
                      onHide: onHide,
                      onAdd: onAdd,
                      showsDragHandle: canMove,
                      label: DataViewSelection.label(for: field.squashedString, labels: labels))
          if index != (fields.count-1) {
            Rectangle().fill(Color("macosDivider").opacity(0.3))
              .frame(maxWidth: .infinity)
              .padding(.horizontal,4)
              .frame(height: 1)
              .padding(.top,2)
          }
          
        }
        .opacity(draggingKey == field.squashedString ? 0.4 : 1)
        .modifier(FieldReorderModifier(key: field.squashedString,
                                       draggingKey: $draggingKey,
                                       onMove: canMove ? onMove : nil))
      }
    }
  
  }
}

private struct FieldReorderModifier: ViewModifier {
  let key: String
  @Binding var draggingKey: String?
  let onMove: ((_ key: String, _ target: String) -> Void)?

  func body(content: Content) -> some View {
    if let onMove = onMove {
      content
        .onDrag {
          draggingKey = key
          return NSItemProvider(object: key as NSString)
        }
        .onDrop(of: [UTType.text], delegate: FieldReorderDropDelegate(targetKey: key,
                                                                      draggingKey: $draggingKey,
                                                                      onMove: onMove))
    } else {
      content
    }
  }
}
