// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct CustomButtonView: View {
    var action: () -> Void
    var iconName: String
    var text: String
    var buttonColor: Color = Color("ButtonHighlighted")
    var iconColor: Color = .white
    var iconSize: CGFloat = 15
    var textSize: CGFloat = 11

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .font(.system(size: iconSize))
                Text(text)
                    .font(.system(size: textSize))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(.leading, 4)
            .padding(.trailing, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct macosMainMenu: View {
  
  @Binding var sidebar : sideBar
  @State var sidebarHistory : sideBar? = nil
  @Binding var fullScreen : Bool
  var backgroundColor : Color = Color("Background")
  @ObservedObject var serverObjects: HostsDataManager
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  
    var body: some View {
      VStack (spacing:5){
        
        CustomButtonView(
            action: {
                sidebar = .hidden
                sidebarHistory = nil
              
              serverObjects.refresh()
              searchHistoryManager.refresh()
            },
            iconName: "magnifyingglass",
            text: "Search",
            buttonColor : sidebar == .hidden ? Color("ButtonHighlighted") : Color("Button")
        )
  

        CustomButtonView(
            action: {
              sidebar = .hosts
              sidebarHistory = nil
              serverObjects.refresh()
              searchHistoryManager.refresh()
            },
            iconName: "server.rack",
            text: "Hosts",
            buttonColor : sidebar == .hosts ? Color("ButtonHighlighted") : Color("Button")
        )
        
        
//        CustomButtonView(
//            action: {
//              sidebar = .develop
//            },
//            iconName: "ellipsis.curlybraces",
//            text: "Develop",
//            buttonColor : sidebar == .develop ? Color("ButtonHighlighted") : Color("Button")
//        )
//        
        CustomButtonView(
            action: {
              sidebar = .settings
              sidebarHistory = nil
            },
            iconName: "gearshape",
            text: "Settings",
            buttonColor : sidebar == .settings ? Color("ButtonHighlighted") : Color("Button")
        )
        

        Spacer()
      }
      .frame(maxWidth: .infinity)
      .padding(.top, fullScreen ? 5 : 0)
      .background(backgroundColor)
    }
}
