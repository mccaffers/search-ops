// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchMainStatusView: View {
  
  @EnvironmentObject var selectedHost: HostDetailsWrap
  @EnvironmentObject var limitObj : LimitObj
  @EnvironmentObject var filterObject : FilterObject
  @EnvironmentObject var serverObjects : HostsDataManager
  
  @State var initialString = true
  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  
  @State var initialMessage = "Welcome to SearchOps"
  @Binding var errorMessage : [ResponseError]
  
  var selectedIndex : String
  var iconSize = CGFloat(22)
  
  var body: some View {
    
    VStack {
      
      if errorMessage.count>0 {
        VStack(alignment:.leading, spacing:10) {
          ForEach(errorMessage.indices, id:\.self) { index in
            
            
            HStack (alignment:.top, spacing:10) {
              
              if errorMessage[index].type == .critical {
                Image(systemName: "exclamationmark.triangle")
                  .font(.system(size: iconSize, weight:.light))
                  .foregroundColor(.red)
              } else if errorMessage[index].type == .warn {
                Image(systemName: "exclamationmark.triangle")
                  .font(.system(size: iconSize, weight:.light))
                  .foregroundColor(.orange)
              } else if errorMessage[index].type == .information {
                Image(systemName: "info.square")
                  .font(.system(size: iconSize, weight:.light))
                  .foregroundColor(Color("TextColor"))
              }
              
              
              VStack(alignment:.leading, spacing:10){
                
                Text(errorMessage[index].title)
                  .font(.system(size: 16, weight:.semibold))
                  .padding(.top,2)
                
                
                Text(errorMessage[index].message)
                  .fixedSize(horizontal: false, vertical: true)
                Button {
                  withAnimation(Animation.linear(duration: 0.3)){
                    errorMessage.removeAll(where: {$0.title == errorMessage[index].title})
                    
                  }
                } label: {
                  Text("Dismiss")
                    .font(.system(size: 14))
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color("Button"))
                    .cornerRadius(5)
                }
              }
              
              
              
              
            }
            .font(.system(size: 14))
            .frame(maxWidth: .infinity, alignment:.leading)
            .padding(.horizontal, 15)
            //						.multilineTextAlignment(.leading)
            .padding(.vertical, 15)
            .background(Color("BackgroundAlt"))
            .cornerRadius(5)
            
          }
          
        }
      } else if selectedHost.item == nil {
        HStack(spacing:5) {
          Spacer()
          Text(initialMessage)
            .font(.system(size: 16))
          Spacer()
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment:.leading)
        .background(Color("BackgroundAlt"))
        .cornerRadius(5)
        .onAppear {
          if initialMessage=="Add a host to search" {
            withAnimation(Animation.linear(duration: 0.5)) {
              initialMessage="Select a host to search"
            }
          } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
              
              if serverObjects.items.count == 0 {
                withAnimation(Animation.linear(duration: 0.5)) {
                  initialMessage="Add a host to search"
                }
              } else {
                withAnimation(Animation.linear(duration: 0.5)) {
                  initialMessage="Select a host to search"
                }
                
              }
            }
          }
          
        }
      } else {
        
        HStack(spacing:5) {
          
          
          Spacer()
          
          
          Image(systemName: "server.rack")
            .font(.system(size: 16, weight:.light))
          
          if let host = selectedHost.item,
             !host.isInvalidated {
            Text(host.name)
              .lineLimit(1)
          } else {
            Text("No host")
          }
          
          Spacer()
          
          
          Image(systemName: "folder")
            .font(.system(size: 16, weight:.light))
          
          if !selectedIndex.isEmpty {
            Text(selectedIndex)
              .lineLimit(1)
          } else {
            Text("No index")
          }
          
          Spacer()
          
        }
        //				.font(.system(size: 14))
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment:.leading)
        .background(Color("BackgroundAlt"))
        .cornerRadius(5)
        
      }
      
      
      
    }
    .onAppear {
      if let version = appVersion?.string {
        initialMessage = "Welcome to SearchOps " + version
      }
    }
    .foregroundColor(Color("TextColor"))
    .padding(.horizontal, 8)
    .padding(.bottom, 4)
  }
  
}
