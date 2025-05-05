// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct ElasticSearchButton: View {
    
    var body: some View {
        VStack {
            NavigationLink(destination: AddElasticView(addServiceNavigationTitle: AddServiceNavigationTitle("ElasticSearch"))){
                VStack  {
                    Image("elasticsearch")
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        
                    Text("ElasticSearch")
                        .padding(.top, 5)
                }
            }
    
        }
          .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct ElasticSearchButton_Previews: PreviewProvider {
    static var previews: some View {
        ElasticSearchButton()
    }
}
#endif
