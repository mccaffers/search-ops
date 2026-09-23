// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

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
        Text(field.squashedString)
          .font(.system(size: 12))
          .padding(.vertical, 8)
      
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

struct FieldsList: View {
    var fields: [SquashedFieldsArray]

    var onHide: (SquashedFieldsArray) -> Void
    var onAdd: (SquashedFieldsArray) -> Void

  var body: some View {
    LazyVStack(spacing:0) {
      ForEach(fields.indices, id: \.self) { index in
        VStack(spacing: 0) {
          
          FieldButton(field: fields[index], 
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
}
