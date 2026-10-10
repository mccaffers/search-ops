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
  /// Shown instead of the index when the search is a data view's pattern
  var dataView: DataView? = nil
  var latency: Duration? = nil
  @Binding var currentWidth: CGFloat
  
    var body: some View {
      VStack {
        HStack (spacing: 5){
          
          Button {
            selection = .None
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
            selection = (selection == .Hosts ? .None : .Hosts)
          } label: {
            Group {
              if let name = hostName {
                Text(name)
              } else {
                Text("Host")
              }
            }
              .padding(6)
              .background(selection == .Hosts ? Color("BackgroundAlt") : Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          
          
          Button {
            selection = (selection == .Indices ? .None : .Indices)
          } label: {
            Group {
              if let dataView = dataView {
                HStack(spacing: 5) {
                  Image(systemName: "rectangle.stack")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color("LabelBackgroundFocus"))
                  Text(dataView.name)
                }
              } else if let index = index {
                Text(index)
              } else {
                Text("Index")
              }
            }
              .padding(6)
              .background(selection == .Indices ? Color("BackgroundAlt") : Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color("LabelBackgroundFocus"), lineWidth: dataView == nil ? 0 : 1)
              )
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          .help(dataView.map { "Data view \($0.name): \($0.pattern)" } ?? (index ?? "Choose an index"))
          Spacer()

          if let latency = latency {
            let latencyColor: Color = latency.isSlowLatency ? .orange : .green
            Text(latency.latencyLabel)
              .monospacedDigit()
              .foregroundColor(latencyColor)
              .padding(6)
              .background(latencyColor.opacity(0.18))
              .clipShape(.rect(cornerRadius: 5))
              .help("Round-trip time of the last search request")
          }

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
