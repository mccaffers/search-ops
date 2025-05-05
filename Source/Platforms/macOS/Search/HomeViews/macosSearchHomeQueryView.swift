// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeQueryView: View {
  @Binding var searchText : String
  @FocusState var focusedField: String?
  @State var selectedQueryStringField = false
  @Binding var localSelectedIndex : String
  @ObservedObject var localFilterObject : FilterObject
  
  @State var backgroundColor : Color = Color("Background")

  
  var body: some View {
    VStack (spacing:5){
      
      Text("Query String")
        .font(.subheadline)
        .foregroundStyle(Color("TextSecondary"))
        .frame(maxWidth: .infinity, alignment: .leading)
      
      
      TextField("", text: $searchText)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
        .font(.system(size: 13))
        .frame(height: 36)
        .background(backgroundColor)
        .clipShape(.rect(cornerRadius: 5))
        .focused($focusedField, equals: "query_string")
        .overlay(
          RoundedRectangle(cornerRadius: 5)
            .stroke(Color("Background"), lineWidth: 1)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 5)
            .stroke(selectedQueryStringField ? Color("LabelBackgroundBorder") : Color("BackgroundAlt"), lineWidth: 1)
        )
        .onChange(of: focusedField, perform: { newValue in
          // selected the textfield view, needs a negative check on selected
          // or swiftui loops forever
          if newValue == "query_string" && !selectedQueryStringField {
            selectedQueryStringField = true
          } else if selectedQueryStringField && newValue != "query_string" {
            selectedQueryStringField = false
          }
          
        })
        .onChange(of: searchText) { newValue in
          localFilterObject.query = QueryObject()
          localFilterObject.query?.values.append(QueryFilterObject(string: newValue))
        }

    }.redacted(reason: localSelectedIndex.isEmpty ? .placeholder : [])
      .onChange(of: localSelectedIndex) { newValue in
        localFilterObject.query = nil
        searchText = ""
        
        if !localSelectedIndex.isEmpty {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            focusedField = "query_string"
            selectedQueryStringField = true
            backgroundColor = Color("BackgroundAlt")
          }
        } else {
          focusedField = nil
          selectedQueryStringField = false
          backgroundColor = Color("Background")
        }
      }
  }
}

