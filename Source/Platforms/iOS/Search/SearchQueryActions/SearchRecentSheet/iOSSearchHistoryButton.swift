// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct iOSSearchHistoryButton: View {
  
  @ObservedObject var serverObjects: HostsDataManager
//  @StateObject var filterObject: FilterObject = FilterObject()
  
  var item : SearchEvent
  @Binding var firstSearchAfterSelectingIndex : Bool
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  var width : CGFloat
  var host: HostDetails
  
  var body: some View {
    
    Button {
      if let historySelectedHost = serverObjects.items.first(where: {$0.id == item.host}) {
        
        var filterObject = FilterObject()
        filterObject.dateField = item.filter?.dateField
        if let relativeRange = item.filter?.relativeRange {
          filterObject.relativeRange = relativeRange
        }
        if let absoluteRange = item.filter?.absoluteRange {
          filterObject.absoluteRange = absoluteRange
        }
        filterObject.query = item.filter?.query
        filterObject.dateField = item.filter?.dateField
        filterObject.sort = item.filter?.sort
        
        request(historySelectedHost, item.index, filterObject)
      }
      
    } label: {
      iOSSearchHistoryButtonLabel(item: item, selectedHost:host, width: width)
    }.buttonStyle(PlainButtonStyle())
    
  }
}
#endif
