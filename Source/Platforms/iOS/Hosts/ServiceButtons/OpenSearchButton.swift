// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct OpenSearchButton: View {
  var body: some View {
    VStack {
      NavigationLink(destination: AddElasticView(addServiceNavigationTitle: AddServiceNavigationTitle("OpenSearch"))){
        VStack  {
          
          ZStack (alignment: .center) {
            Rectangle()
              .fill(Color(red: 1/255, green: 52/255, blue: 85/255))
              .cornerRadius(10) /// make the background rounded
            Image("opensearch_dark")
              .resizable()
              .frame(width: 40, height: 40, alignment: .center)
          }.frame(width: 50, height: 50, alignment: .center)
          
          Text("OpenSearch")
            .padding(.top, 5)
          
        }
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity)
  }
}
#endif
