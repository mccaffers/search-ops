// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchResultsPlaceholderView: View {
    var body: some View {
        HStack(spacing:10) {
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("BackgroundAlt"))
                .frame(maxWidth:50)
                .frame(height:35)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("BackgroundAlt"))
                .frame(maxWidth: .infinity)
                .frame(height:35)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("BackgroundAlt"))
                .frame(width: 100)
                .frame(height:35)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("BackgroundAlt"))
                .frame(maxWidth: .infinity)
                .frame(height:35)
        }.padding(.horizontal, 5)
            .padding(.top, 10)
        
        ForEach((1...1).reversed(), id: \.self) { index in
            
            HStack(spacing:10) {
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("BackgroundAlt"))
                    .frame(maxWidth: 50)
                    .frame(height:20)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("BackgroundAlt"))
                    .frame(maxWidth: .infinity)
                    .frame(height:20)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("BackgroundAlt"))
                    .frame(width: 100)
                    .frame(height:20)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("BackgroundAlt"))
                    .frame(maxWidth: .infinity)
                    .frame(height:20)
            }.padding(.horizontal, 5)
                .padding(.top, 5)
            
        }
        
        Spacer()
        
    }
}
