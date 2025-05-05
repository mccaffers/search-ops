// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeInitView: View {
  
  @Binding var localSelectedHost: HostDetails?
  @Binding var localSelectedIndex : String
  @ObservedObject var localFilterObject : FilterObject = FilterObject()
  @Binding var indexArray : [String]
  @Binding var showing : macosSearchWelcomeScreenMainView
  
  @ObservedObject var serverObjects : HostsDataManager
  @Binding var sidebar : sideBar
  @Binding var selection: macosSearchViewEnum
  
  var updateIndexArray : () async -> ()
  var mappingRequest : () async -> ()
  var selectedHostFunc : (_ host:  HostDetails) -> ()
  
  var body: some View {
    VStack(spacing:0) {
      Text("New Search")
        .font(.system(size: 22, weight:.light))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 5)
      
      
      macosSearchHomeHostsView(serverObjects: serverObjects,
                               localSelectedHost: $localSelectedHost,
                               localSelectedIndex: $localSelectedIndex,
                               indexArray: $indexArray,
                               localFilterObject: localFilterObject,
                               showing: $showing,
                               sidebar:$sidebar,
                               selection:$selection,
                               updateIndexArray: {
        Task {
          
          await updateIndexArray()
          
        }
      }, unselectedHost: {},
                               selectedHost: selectedHostFunc)
    }
    
  }
}
