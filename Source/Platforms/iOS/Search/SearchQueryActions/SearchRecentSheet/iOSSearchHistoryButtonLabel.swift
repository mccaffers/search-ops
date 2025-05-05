// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct iOSSearchHistoryButtonLabel: View {
  
  var item : SearchEvent
  var selectedHost: HostDetails
  var width : CGFloat
  
  var labelTextColor = Color("macosHomeLabels")
  
  private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
  
  var indexWidth : CGFloat {
    (width * 0.33) - (idiom == .pad ? 20 : 0)
  }
  
  var queryWidth : CGFloat {
    (width * 0.33) - (idiom == .pad ? 20 : 0)
  }
  
  var dateWidth : CGFloat {
    (width * 0.33) - (idiom == .pad ? 20 : 0)
  }
  
  var body: some View {
    VStack (spacing:0){

        HStack(spacing:0) {
          
          VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
              Text(selectedHost.name.truncated(to: 14, addEllipsis: false))
                .foregroundStyle(Color("TextSecondary"))
              Text(item.index.truncated(to: 14, addEllipsis: false))
            }.padding(.leading, 5)
          }.frame(width: indexWidth, alignment:.leading)
            
          if let searchValues = item.filter?.query?.values {
            if searchValues.count == 1,
               let searchTerm = item.filter?.query?.values.first?.string {
              Text(searchTerm.truncated(to: 14, addEllipsis: false))
                .frame(width: queryWidth, alignment:.leading)
            } else if searchValues.count > 1 {
              Text("Multiple Strings")
                .italic()
                .foregroundStyle(Color("TextSecondary"))
                .frame(width: queryWidth, alignment:.leading)
            }
              
          } else {
            Text("*")
              .frame(width: queryWidth, alignment:.leading)
          }
          
          if let dateField = item.filter?.dateField {
            if let relativeRange = item.filter?.relativeRange {
              Text(relativeRange.GeneratePrettyTimeString())
                .frame(width: dateWidth, alignment:.leading)
            } else if let absoluteRange = item.filter?.absoluteRange {
              Text(absoluteRange.generatePrettyString())
       
                .frame(width: dateWidth, alignment:.leading)
            }
          } else {
            Text("None")
              .italic()
              .frame(width: dateWidth, alignment:.leading)
          }
          
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .background(Color("BackgroundAlt"))
        .font(.system(size: 13))
    }
    .padding(.horizontal, idiom == .pad ? 20 : 0)
  }
}
#endif
