// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchFieldSheetHeader: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var updatedFieldsNotification : UUID
 
    var body: some View {
        HStack(
            alignment: .center,
            spacing: 2
        ) {
            
            Text("Field Selection")
                .font(.system(size: 26, weight: .bold))
            
            Spacer()
           
            Button {
                updatedFieldsNotification=UUID()
                dismiss()
                
            } label: {
                                  
                VStack (spacing:0) {
                    HStack {
                        Text("Save")
                    }
                    .foregroundColor(Color("TextColor"))
                }
                .padding(10)
                .background(Color("PositiveButton"))
                .cornerRadius(5)
            }

        }
        .frame(height: 60)
        .padding(.top, 20)
        .padding(.bottom, 5)
        .padding(.horizontal, 15)
    }
}
