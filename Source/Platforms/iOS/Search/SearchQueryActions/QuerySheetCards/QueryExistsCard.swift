// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct QueryExistsCard: View {
    var body: some View {
        VStack(spacing:0) {
            
            HStack {
            Text("Exists")
                .font(.system(size: 24, weight:.bold))
                
//                .padding(.bottom, 10)
                
            HStack(spacing:3) {
                    Text(Image(systemName: "slash.circle.fill"))
                    Text("inactive")
                }
                .font(.system(size: 14))
                .padding(8)
                .foregroundColor(.white)
                .background(Color("LabelBackgrounds"))
                .cornerRadius(5)
                
                
            Spacer()
                
            Button {
//                showingQueryV/iew = true
            } label: {
                
                Text(Image(systemName: "chevron.right"))
                    .font(.system(size: 22))
                    .foregroundColor(Color("LabelBackgroundFocus"))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
//                    .background(Color("ButtonExp"))
                    .cornerRadius(5)
                
            }
            }.frame(maxWidth: .infinity, alignment:.leading)
           

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color("BackgroundAlt"))
        .cornerRadius(5)
        .padding(.horizontal, 10)
    }
}

struct QueryExistsCard_Previews: PreviewProvider {
    static var previews: some View {
        QueryExistsCard()
    }
}
