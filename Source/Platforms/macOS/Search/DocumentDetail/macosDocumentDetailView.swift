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

struct macosDocumentDetailView: View {
  
  @ObservedObject var itemDetail: DocumentDetail
  @State private var offset: CGFloat = 300
  @State private var view : macosDocumentView = .Document
  @State private var jsonDocument = ""
  
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
                if let values = document[key] as? [String],
                   containsCharacters(values) {
                  Text(key)
                    .foregroundColor(Color("LabelBackgroundFocus"))
                  
                  ForEach(values, id: \.self) { value in
                    Text(value)
                      .padding(.leading, 10)
                      .padding(.bottom, 10)
                  }
                }
              }
            }
            .padding(.top, 10)
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

#endif
