// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct FieldButtonHover: View {
    @State private var isHovered = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
              Image(systemName: "chevron.up")
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
            .background(Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .opacity(isHovered ? 0.7 : 0.1)
            .onHover { hovering in
                withAnimation {
                    isHovered = hovering
                }
            }
        }
        .niceButton(
            foregroundColor: .white,
            backgroundColor: .clear,
            pressedColor: .clear
        )
    }
}

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


struct FieldActiveButton: View {
  var isDate: Bool
    var isSelected: Bool
    var action: () -> Void
  
  func symbol(active: Bool) -> String {
    if active {
      if isDate {
        return "bolt.circle.fill"
      } else {
        return "circle.fill"
      }
    } else {
      if isDate {
        return "bolt.circle"
      } else {
        return "circle"
      }
    }
  }

    var body: some View {
      Image(systemName: symbol(active:isSelected))
            .font(.system(size: 14))
            .contentShape(Rectangle())
    }
}

struct FieldButton : View {
  
  var field: SquashedFieldsArray
  @Binding var renderedObjects: RenderObject?
  var onHide: (SquashedFieldsArray) -> Void
  var onAdd: (SquashedFieldsArray) -> Void
  
  @State var isFocused = false
  
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
//        isFocused = false
      } else {
        onAdd(field)
//        isFocused = true
      }
      
//      if field.type != "date" {
//        if isFocused {
//          onHide(field)
//          isFocused = false
//        } else {
//          onAdd(field)
//          isFocused = true
//        }
//      } else {
//        if renderedObjects?.dateField?.fieldParts != field.fieldParts {
//            renderedObjects?.dateField = field
//        } else {
//            renderedObjects?.dateField = nil
//        }
//      }
    } label: {
      HStack(spacing:4) {
        
//        FieldActiveButton(isDate: false,
//                          isSelected: isFocused) {}
        
        Text(field.squashedString)
          .font(.system(size: 12))
          .padding(.vertical, 8)
      
        
        Spacer()

        Group {
//          if field.type != "date" {
//            FieldActiveButton(isDate: field.type == "date",
//                              isSelected: isFocused) {}
//          } else {
//            FieldActiveButton(isDate: field.type == "date",
//                              isSelected: renderedObjects?.dateField?.fieldParts == field.fieldParts) {}
//          }
          
        
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
struct FieldsList: View {
    var fields: [SquashedFieldsArray]
    @EnvironmentObject var filterObject: FilterObject
    @Binding var renderedObjects: RenderObject?

    var onHide: (SquashedFieldsArray) -> Void
    var onAdd: (SquashedFieldsArray) -> Void

  var body: some View {
    LazyVStack(spacing:0) {
      ForEach(fields.indices, id: \.self) { index in
        VStack(spacing: 0) {
          
          FieldButton(field: fields[index], 
                      renderedObjects: $renderedObjects,
                      onHide: onHide,
                      onAdd: onAdd)
          if index != (fields.count-1) {
            Rectangle().fill(Color("macosDivider").opacity(0.3))
              .frame(maxWidth: .infinity)
              .padding(.horizontal,4)
              .frame(height: 1)
              .padding(.top,2)
          }
          
        }
      }
    }
  
  }

    private func renderSortButton(for item: SquashedFieldsArray) -> some View {
        if item.type == "date" {
            if let dateField = renderedObjects?.dateField, filterObject.sort != nil {
                return AnyView(
                    Button {
                        if filterObject.sort?.order == .Descending {
                            filterObject.sort = SortObject(order: .Ascending, field: item)
                        } else {
                            filterObject.sort = SortObject(order: .Descending, field: item)
                        }
                    } label: {
                        Image(systemName: filterObject.sort?.order == .Ascending ? "chevron.up" : "chevron.down")
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                            .background(Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .niceButton(
                        foregroundColor: .white,
                        backgroundColor: .clear,
                        pressedColor: .clear
                    )
                )
            } else {
              return AnyView(EmptyView())
            }
        } else {
          return AnyView(EmptyView())
        }
    }

    private func renderVisibilityButton(for item: SquashedFieldsArray) -> some View {
        if item.type != "date" {
          return AnyView(FieldActiveButton(isDate: false, isSelected: item.visible) {
                if !item.visible {
                    onAdd(item)
                } else {
                    onHide(item)
                }
            })
        } else {
            return AnyView(FieldActiveButton(isDate: true, isSelected: renderedObjects?.dateField?.fieldParts == item.fieldParts) {
                if renderedObjects?.dateField?.fieldParts != item.fieldParts {
                    renderedObjects?.dateField = item
                } else {
                    renderedObjects?.dateField = nil
                }
            })
        }
    }
}
