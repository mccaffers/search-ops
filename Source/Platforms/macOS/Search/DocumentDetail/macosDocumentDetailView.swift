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

struct DocumentFieldHeaderView: View {
  let key: String
  let isVisible: Bool
  let onToggle: () -> Void
  @State private var isHovered = false

  var body: some View {
    HStack(alignment: .center, spacing: 6) {
      Text(key)
        .foregroundColor(Color("LabelBackgroundFocus"))

      Button(action: onToggle) {
        Image(systemName: isVisible ? "list.bullet.circle.fill" : "list.bullet.circle")
          .font(.system(size: 13))
          .foregroundColor(
            isVisible
              ? Color.accentColor
              : (isHovered ? Color("LabelBackgroundFocus") : Color("TextSecondary"))
          )
          .frame(width: 16, height: 16)
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .help(isVisible ? "Hide field from results list" : "Show field in results list")
      .accessibilityLabel(isVisible ? "Hide \(key) from results list" : "Show \(key) in results list")
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
}

struct macosDocumentDetailView: View {
  
  @ObservedObject var itemDetail: DocumentDetail
  @Binding var fields: [SquashedFieldsArray]
  @Binding var onlyVisibleFields: [SquashedFieldsArray]
  @Binding var updatedFieldsNotification: UUID
  @State private var offset: CGFloat = 300
  @State private var view : macosDocumentView = .Document
  @State private var jsonDocument = ""
  @State private var refreshId = UUID()
  
  func isFieldVisible(_ key: String) -> Bool {
    Self.isFieldVisible(key, in: fields, onlyVisibleFields: onlyVisibleFields)
  }

  func toggleFieldVisibility(_ key: String) {
    _ = Self.toggleFieldVisibility(key, fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    updatedFieldsNotification = UUID()
    refreshId = UUID()
  }

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
          
          Button {
            if view == .Document {
              view = .JSON
            } else {
              view = .Document
            }
          } label: {
            Group {
              if view == .Document {
                Text("View as JSON")
              } else {
                Text("View as Document")
              }
            }
            .padding(10)
            .background(Color("Background"))
            .clipShape(.rect(cornerRadius: 5))
          }.buttonStyle(PlainButtonStyle())
            .padding(.trailing, 10)
          
        }
        .padding(.vertical, 5)
        .background(Color("Button"))
        
        
        if view == .Document {
          ScrollView {
            VStack(alignment: .leading, spacing:0) {
              ForEach(document.keys.sorted(), id: \.self) { key in
                if let rawValue = document[key],
                   let displayValue = DocumentDetail.formatDisplayValue(rawValue) {
                  DocumentFieldHeaderView(
                    key: key,
                    isVisible: isFieldVisible(key),
                    onToggle: {
                      toggleFieldVisibility(key)
                    }
                  )
                  
                  Text(displayValue)
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
                }
              }
            }
            .padding(.top, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            
          }
          .id(refreshId)
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
    .padding(.bottom, 25)
    .frame(maxWidth: 600)
    .padding(.trailing, 10)
    .padding(.top, 36)
    .offset(x: offset)
    .animation(.spring(response: 0.4, dampingFraction: 1, blendDuration: 0), value: offset)
    .onAppear {
      offset = 0
    }
    .onDisappear {
      itemDetail.showingView = false
      itemDetail.item = nil
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

  @discardableResult
  public static func toggleFieldVisibility(
    _ key: String,
    fields: inout [SquashedFieldsArray],
    onlyVisibleFields: inout [SquashedFieldsArray]
  ) -> Bool {
    let fieldInFields = fields.first(where: { $0.squashedString == key })
    let fieldInVisible = onlyVisibleFields.first(where: { $0.squashedString == key })

    let newVisible: Bool
    if let field = fieldInFields {
      field.visible.toggle()
      newVisible = field.visible
    } else if let visibleField = fieldInVisible {
      visibleField.visible.toggle()
      newVisible = visibleField.visible
    } else {
      newVisible = true
    }

    // Synchronize fields
    if let field = fieldInFields {
      field.visible = newVisible
    } else {
      let targetField: SquashedFieldsArray
      if let existingVisible = fieldInVisible {
        targetField = existingVisible
      } else {
        let parts = key.components(separatedBy: ".")
        targetField = SquashedFieldsArray(squashedString: key, fieldParts: parts)
      }
      targetField.visible = newVisible
      fields.append(targetField)
    }

    // Synchronize onlyVisibleFields using the exact same instance
    if let visibleField = fieldInVisible {
      visibleField.visible = newVisible
    } else if newVisible {
      let fieldToAdd = fieldInFields ?? fields.first(where: { $0.squashedString == key })!
      onlyVisibleFields.append(fieldToAdd)
    }

    return newVisible
  }
}

#endif
