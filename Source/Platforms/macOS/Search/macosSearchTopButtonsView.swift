// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)
struct macosSearchTopButtonsView: View {
  
  @Binding var macosSearchRouterPath : macosSearchRouterPath
  @Binding var selection: macosSearchViewEnum
  @Binding var showFilterSidebar :  Bool
 
  var hostName : String? = nil
  var index: String? = nil
  @Binding var currentWidth: CGFloat
    var body: some View {
      VStack {
        HStack (spacing: 5){
          
          Button {
            macosSearchRouterPath = .WelcomeScreen
          } label: {
            Image(systemName: "house")
              .font(.system(size: 16))
              .padding(5)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          
          
          Button {
            selection = .Hosts
          } label: {
            Group {
              if let name = hostName {
                Text(name)
              } else {
                Text("Host")
              }
            }
              .padding(6)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          
          
          Button {
            selection = .Indices
          } label: {
            Group {
              if let index = index {
                Text(index)
              } else {
                Text("Index")
              }
            }
              .padding(6)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          Spacer()
          
          
          Button {
            showFilterSidebar.toggle()
            if showFilterSidebar {
              currentWidth = 300
            }
          } label: {
            
            Group {
              if showFilterSidebar {
                HStack{
                  Image(systemName: "arrow.right")
                  Text("Hide Fields")
                }
              } else {
                HStack{
                  Image(systemName: "arrow.left")
                  Text("Show Fields")
                }
              }
            }
              .padding(6)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          
        }.padding(.trailing, 5)
      }
    }
}

#endif
§