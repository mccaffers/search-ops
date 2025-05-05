// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHistoryButtonLabel: View {
  
  var item : SearchEvent
  var selectedHost: HostDetails
  var width : CGFloat
  
  var labelTextColor = Color("macosHomeLabels")
  @State var onHover = false
  var body: some View {
    VStack (spacing:0){
      
        //      let historySelectedHost = serverObjects.items.first(where: {$0.id == myList[index].host})
        
        HStack(spacing:0) {
          
          HStack(spacing:0){
            Text(selectedHost.name)
              .padding(.leading, 5)
          }
            .frame(width: width*0.15, alignment:.leading)
          
          
          Text(item.index)
            .frame(width: width*0.15, alignment:.leading)
          
          
          if let searchTerm =  item.filter?.query?.values.first?.string {
            Text(searchTerm)
              .frame(width: width*0.4, alignment:.leading)
          } else {
            Text("*")
              .frame(width: width*0.4, alignment:.leading)
          }
          
          if let dateField = item.filter?.dateField {
            if let relativeRange = item.filter?.relativeRange {
              Text(relativeRange.GeneratePrettyTimeString())
                .font(.system(size: 12))
                .frame(width: width*0.3, alignment:.leading)
            } else if let absoluteRange = item.filter?.absoluteRange {
              Text(absoluteRange.generatePrettyString())
                .font(.system(size: 12))
                .frame(width: width*0.3, alignment:.leading)
            }
          } else {
            Text("None")
              .italic()
              .frame(width: width*0.3, alignment:.leading)
          }
          
        }      
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .background(Color("BackgroundAlt").opacity(onHover ? 1 : 0.65))

    }
    .onHover { hover in
      onHover = hover
    }

  }
}
