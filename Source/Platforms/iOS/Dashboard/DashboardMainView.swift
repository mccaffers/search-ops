// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct DashboardMainView: View {
    var body: some View {

        
        NavigationStack {
            VStack (spacing:0) {
                
                DemoDragRelocateView()
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("Background"))
            .toolbar {
                Button {
                    //
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                }

            }
#if os(iOS)
            .navigationBarTitle("Dashboard")
#endif
        }
#if os(iOS)
        .navigationViewStyle(.stack)
#endif
        
        
    }
}
