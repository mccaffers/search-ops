// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct MainSheetCardHostView: View {
  
  @EnvironmentObject var selectedHost: HostDetailsWrap
  @EnvironmentObject var serverObjects : HostsDataManager
  @State var showingHost : Bool = false
  
  var body: some View {
    VStack(alignment: .leading, spacing:0){
      HStack (alignment:.center){
        
        Text("Host")
          .font(.system(size: 26, weight:.bold))
        
        
        Spacer()
        
        if serverObjects.items.count > 1 {
          Button {
            showingHost = true
          } label: {
            
            Text(Image(systemName: "chevron.right"))
              .font(.system(size: 22))
              .padding(.vertical, 5)
              .padding(.horizontal, 10)
              .foregroundColor(.white)
              .background(Color("Button"))
              .cornerRadius(5)
            
          }
        }
        
        
      }.frame(maxWidth: .infinity)
        .padding(.bottom, 5)
        .padding(.top, 5)
      
      VStack(alignment:.leading) {
        if let host = selectedHost.item {
          Button {
            selectedHost.item = nil
          } label: {
            VStack(
              alignment: .leading,
              spacing: 10
            ) {
              Text("\(host.name)")
              
            }
            .padding(10)
            .foregroundColor(.white)
            .background(Color("ButtonHighlighted"))
            .cornerRadius(5)
          }
        } else if serverObjects.items.count == 0 {
          Text("No saved hosts")
            .frame(maxWidth: .infinity, alignment:.leading)
            .padding(.vertical, 10)
          
        } else {
          WrappingHStack(horizontalSpacing: 5) {
            
            ForEach(serverObjects.items.prefix(5), id: \.self) {  index in
              Button {
                if selectedHost.item == index {
                  selectedHost.item = nil
                } else {
                  selectedHost.item = index
                }
              } label: {
                VStack(
                  alignment: .leading,
                  spacing: 10
                ) {
                  Text("\(index.name)")
                  
                }
                .padding(10)
                .foregroundColor(.white)
                .background(selectedHost.item?.id == index.id ? Color("ButtonHighlighted") : Color("Button"))
                .cornerRadius(5)
              }
            }
            
          }
        }
        
      }.frame(maxWidth: .infinity, alignment: .leading)
      
      
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 15)
    .background(Color("BackgroundAlt"))
    .cornerRadius(5)
    .padding(.top, 10)
    .padding(.horizontal, 10)
    .navigationDestination(isPresented:$showingHost, destination: {
      SearchHostList()
    })
  }
}
#endif
