// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchQueryQuickButtons: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
    
        HStack {
            
            Button {
//                queryObj.queryString="*"
                dismiss()
            } label: {
                VStack (spacing:0) {
                    Text("*")
                        .font(.system(size: 20, weight:.regular))
                        .padding(.top, 6)
                        .padding(.horizontal, 8)
                 
                }
                    .frame(height: 45)
                    .padding(.horizontal, 10)
                    .foregroundColor(.white)
                    .background(Color("Button"))
                    .cornerRadius(5)
            }
            
            Button {
//                queryObj.queryString="success"
                dismiss()
            } label: {
                Text("success")
                    .font(.system(size: 16, weight:.light))
                    .frame(height: 45)
                    .padding(.horizontal, 10)
                    .foregroundColor(.white)
                    .background(Color("Button"))
                    .cornerRadius(5)
                
            }
            
            Button {
//                queryObj.queryString="new"
                dismiss()
            } label: {
                Text("new")
                    .font(.system(size: 16, weight:.light))
                    .frame(height: 45)
                    .padding(.horizontal, 10)
                    .foregroundColor(.white)
                    .background(Color("Button"))
                    .cornerRadius(5)
                
            }
            
            Button {
//                queryObj.queryString="error"
                dismiss()
            } label: {
                Text("error")
                    .font(.system(size: 16, weight:.light))
                    .frame(height: 45)
                    .padding(.horizontal, 10)
                    .foregroundColor(.white)
                    .background(Color("Button"))
                    .cornerRadius(5)
                
            }
            
            Spacer()
        }
        .padding(.top, 5)
        .padding(.horizontal, 15)
    }
}
