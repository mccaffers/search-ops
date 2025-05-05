// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchQueryCommandsView: View {

    
    var label : String
    @Binding var makeSearchRequest: Bool
    
    var body: some View {

        HStack (spacing: 10) {
            
            Button {
                makeSearchRequest=true
            } label: {
                VStack {
                    Text(label)
                        .foregroundColor(ButtonColor.Text(""))
                        .padding(.horizontal, 10)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(Color("ButtonExp"))
                .cornerRadius(5)
            }.frame(maxWidth: .infinity)
        }
        
    }
}

