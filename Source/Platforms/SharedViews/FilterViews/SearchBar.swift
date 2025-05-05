// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct SearchBar: View {
 
  var showAllButton = false
    @Binding var searchTerm: String
   
    @State private var selected: Bool = false
    @FocusState var focusedField: FocusField?
  
    var onSearch: (String) -> Void
  var showAll: () -> Void
  
    var body: some View {
        HStack(spacing: 5) {
            if showAllButton {
                Button {
                  showAll()
                } label: {
                    Text("Show all")
                        .padding(10)
                        .foregroundColor(.white)
                        .background(Color("Button"))
                        .cornerRadius(5)
                }.padding(.leading, 10)
            }
            
            TextField("Search", text: $searchTerm)
                .textFieldStyle(SelectedTextStyle(focused: $selected))
                .focused($focusedField, equals: .field)
#if os(iOS)
                .keyboardType(.alphabet)
                .textInputAutocapitalization(.none)
#endif
                .textContentType(.oneTimeCode)
                .autocorrectionDisabled(true)
                .onChange(of: searchTerm, perform: onSearch)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .onAppear {
#if os(iOS)
                    UITextField.appearance().clearButtonMode = .whileEditing
#endif
                }
        }
    }
}
