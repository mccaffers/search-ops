// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeHostsView: View {
  
  @ObservedObject var serverObjects : HostsDataManager
  
  @Binding var localSelectedHost: HostDetails?
  @Binding var localSelectedIndex : String
  @Binding var indexArray : [String]
  @ObservedObject var localFilterObject : FilterObject
  @Binding var showing : macosSearchWelcomeScreenMainView
  @Binding var sidebar : sideBar
  @Binding var selection: macosSearchViewEnum
  var updateIndexArray : () async -> ()
  
  @State var hoveringActiveButton = false
  
  var unselectedHost : () -> ()
  var selectedHost : (_ host:  HostDetails) -> ()
  
  var body: some View {
    
    VStack (alignment: .leading, spacing:5) {
      
      Text("My Hosts")
        .font(.subheadline)
        .foregroundStyle(Color("TextSecondary"))
      
      if let localSelectedHost = localSelectedHost {
        
        HStack {
          Button {
//            self.localSelectedHost = nil
//            localSelectedIndex = ""
//            indexArray = []
//            localFilterObject.clear()
//            withAnimation {
//              showing = .All
//            }
            
            unselectedHost()
          } label: {
            Text(localSelectedHost.name)
              .padding(10)
              .background(hoveringActiveButton ? Color("Button") : Color("Background"))
              .clipShape(.rect(cornerRadius: 5))
          }
          .buttonStyle(PlainButtonStyle())
          .onHover { hover in
            hoveringActiveButton = hover
          }
          if hoveringActiveButton {
            Image(systemName: "xmark.circle")
              .bold()
              .padding(.leading, -15)
              .padding(.top, -25)
          }
        }
        
      } else {
        
        WrappingHStack(horizontalSpacing: 5) {
          
          
          ForEach(serverObjects.items, id:\.id) { item in
            Button {
         
              selectedHost(item)
//                withAnimation {
//                  localSelectedHost = item
//                  showing = .NewSearch
//                }
//                Task {
//                  await updateIndexArray()
//                }
                
              
            } label: {
              Text(item.name)
                .padding(10)
                .background(localSelectedHost == item ? Color("ButtonHighlighted") : Color("Button"))
                .clipShape(.rect(cornerRadius: 5))
            }
            .buttonStyle(PlainButtonStyle())
            
          
          }
          
          Button {
            sidebar = .hosts
            selection = .HostManagement
          } label: {
            HStack(spacing:4) {
              Image(systemName: "plus.app")
              Text("New host")
            }
            .padding(10)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
          }.buttonStyle(PlainButtonStyle())
          
          
        }
      }
    }
  }
}
//
//#Preview {
//    macosSearchHomeHostsView()
//}
