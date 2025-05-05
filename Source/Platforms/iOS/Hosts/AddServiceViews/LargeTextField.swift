// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct LargeTextField: View {
    
    var name: String
    @Binding var value: String
    
    @FocusState var focusedField: String?
    @Binding var currentField: String
    
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        
        VStack {
            
            TextEditor(text:$value)
                .focused($focusedField, equals: name)
                .scrollContentBackground(.hidden)
								.accentColor(Color("TextColor"))
								.foregroundColor(Color("TextColor"))
								.background(
										RoundedRectangle(cornerRadius: 5, style: .continuous)
												.stroke(Color("LabelBackgroundFocus"), lineWidth: 2)
								)
                .padding(.bottom, 10)
            
            Button {
                dismiss()
                
            } label: {
                Text("Dismiss")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color("Button"))
										.foregroundColor(.white)
                    .cornerRadius(5)
            }

        }
        .padding(.bottom, 10)
        .padding(.horizontal, 15)
        .onAppear {
            Task { @MainActor in
                self.focusedField = name
            }
            
            currentField = name;
        }
        .background(Color("Background"))
#if os(iOS)
        .navigationBarTitle("Edit " + name)
      
        .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
#endif
        
    }
}

struct LargeTextField_Previews: PreviewProvider {
    static var previews: some View {
        LargeTextField(name: "test", value: .constant(""), currentField: .constant("") )
    }
}
