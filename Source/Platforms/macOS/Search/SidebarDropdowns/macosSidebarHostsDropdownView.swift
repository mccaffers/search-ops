// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSidebarHostsDropdownView: View {
  
  var items : [HostDetails]
  @Binding var selectedHost: HostDetails?
  @Binding var selection: macosSearchViewEnum
  @Binding var fullScreen : Bool
  
  var body: some View {
    VStack {
      
      VStack (alignment: .leading, spacing:0) {


        Text("Hosts")
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.title2)
          .padding(.leading, 10)
          .padding(.top, 15)
          .padding(.bottom, 10)
          .background(Color("Background"))
          .padding(.bottom, 5)
        
        
        VStack(spacing:0){
          ForEach(items.indices, id: \.self) {  index in
            if !items[index].isInvalidated {
              
              HStack {
                let item = items[index]
                macosSideBarHostsButton(selectedHost: $selectedHost,
                                        selection: $selection,
                                        item: item)
              }
              .padding(.horizontal, 5)
              .padding(.bottom, 5)
              
//              if index != (items.count-1) {
//                Rectangle().fill(Color("Background"))
//                  .frame(maxWidth: .infinity)
//                  .padding(.leading, 10)
//                  .frame(height: 1).opacity(0.5)
//              }
            }
          }
          
        }
        .frame(maxWidth: .infinity,alignment: .leading)
        
   
      }
      .frame(maxWidth: .infinity,alignment: .leading)

      .background(Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
//      .shadow(color: Color("Background"), radius: 5, x: 0, y: 0)
      .padding(.leading,10)
      Spacer()
      
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, 10)
    
  }
  
}

