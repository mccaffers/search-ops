// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchLimitView: View {
    
//    @EnvironmentObject var limitObj : LimitObj
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Button {
//                    limitObj.size = 25
                    dismiss()
                } label: {
                    VStack {
                        Text("25")
                    }
                    .padding(10)
                    .background(Color("Button"))
                    .cornerRadius(5)
                }
                
                Button {
//                    limitObj.size = 50
                    dismiss()
                } label: {
                    VStack {
                        Text("50")
                    }
                    .padding(10)
                    .background(Color("Button"))
                    .cornerRadius(5)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .navigationTitle("Limit")
    }
}

