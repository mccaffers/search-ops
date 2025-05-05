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
struct ServerItemViewActionsView: View {
  
  @Environment(\.dismiss) private var dismiss
  
  var item: HostDetails
  
  @State private var presentAlert : Bool = false
  @State private var testConnectionPressed: Bool = false
  @State private var editConnectionPressed: Bool = false
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 5
    ) {
      
     
      VStack(
        alignment: .leading,
        spacing: 10
      ) {
        Button(action: {
          testConnectionPressed=true
        }, label: {
          Text("Test Connection")
            .padding(.vertical, 15)
            .font(.system(size: 15))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .background(Color("Button"))
            .cornerRadius(5.0)
        })
        .frame(maxWidth: .infinity, alignment: .center)
        
        Button(action: {
          editConnectionPressed=true
        }, label: {
          Text("Edit Connection")
            .font(.system(size: 15))
            .foregroundColor(.white)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(Color("Button"))
            .cornerRadius(5.0)
        })
        .frame(maxWidth: .infinity, alignment: .center)
        
      }.padding(.horizontal, 20).padding(.vertical, 5)
    }.padding(.bottom, 10)
      .navigationDestination(isPresented: $testConnectionPressed, destination: {
        TestingConnectionView(item: item)
      })
      .navigationDestination(isPresented: $editConnectionPressed, destination: {
        AddElasticView(item: item.generateCopy(),
                       addServiceNavigationTitle: AddServiceNavigationTitle("ElasticSearch"))
        
      })
    
  }
}
#endif
