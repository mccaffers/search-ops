// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchFavouritesView: View {
    
    @State var selection : HistoryState = HistoryState.Recent
    
    var body: some View {
        VStack {
            SearchHistoryPicker(selection: $selection)
            
            if selection == .Favourites {
                SearchFavouritesList()
            } else if selection == .Recent {
                SearchRecentList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background"))
        .navigationTitle("History")
                    
    }
}
