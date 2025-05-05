// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

#if os(iOS)
struct ServerItemView: View {
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var serverObjects : HostsDataManager
  
  var item: HostDetails
  
  @State var validItem: Bool = true
  @State var refresh = UUID()
  
  func DetechItem(_ item: HostDetails) -> HostDetails {
    return HostDetails()
  }
  
  var body: some View {
    ScrollView {
      VStack (spacing:5){
        if(!item.isInvalidated) {
          ServerItemDetailsView(item: item)
            .padding(.top, 10)
          HostAddDivider()
          ServerItemViewActionsView(item:item)
          HostAddDivider()
          ServerItemViewActionsDeleteView(item:item)
        }
        else {
          Spacer()
        }
      }
    }
    .id(refresh)
    .onAppear {
      serverObjects.refresh()
      refresh=UUID()
    }
    .background(Color("Background"))
    .frame(maxWidth: .infinity, alignment: .leading)
    .navigationTitle(!item.isInvalidated ? item.name : "")
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
    
  }
}
#endif
