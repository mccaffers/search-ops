// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import OrderedCollections
import SwiftyJSON

#if os(iOS)
enum DocumentDetailState: Hashable {
    case JSON
    case Fields
}

struct SearchDetailView: View {
  
  @ObservedObject var itemDetail : DocumentDetail
  @State var selection : DocumentDetailState = DocumentDetailState.Fields
  @Binding var presentedSheet: SearchSheet?
  @Binding var fields : [SquashedFieldsArray]
  @Binding var showDateInputView: DateQuery?
  
  func returnJson (input:OrderedDictionary<String, Any>) -> String {
    
    var myDic = Dictionary<String, Any>()
    for item in input {
      
      myDic.updateValue(item.value, forKey: item.key)
    }
    
    let jsonString = JSON(myDic).rawString(options:[.sortedKeys, .withoutEscapingSlashes, .prettyPrinted]) ?? ""
    return jsonString
    
  }
  
  @State var contents : String = ""
  @State var toolbarButtonString : String = "JSON"
  @State var navigationBarTitle : String = "Document"

#if os(iOS)
  @State var navigationTitleSize : NavigationBarItem.TitleDisplayMode = .large
#endif

  var body: some View {
    Group {
      if selection == .JSON {
        DetailJSONViewer(contents:contents.prettifyJSON())
      } else {
        ScrollView {
          VStack(spacing:0) {
            //            DetailViewPicker(selection: $selection)
            //                .padding(.bottom, selection == .Fields ? 10 : 0)
            //
            if selection == .Fields {
              DetailFieldsView(itemDetail: itemDetail,
                               presentedSheet: $presentedSheet,
                               fields: fields,
                               showDateInputView:$showDateInputView)
              
            }
          }
        }
      }
    }
    .background(Color("Background"))
    .onAppear {
      if let item = itemDetail.item {
        contents = returnJson(input: item).trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }
    .onDisappear {
      //            itemDetail.item = nil
      itemDetail.showingView = false
    }
#if os(iOS)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(toolbarButtonString) {
          if selection == .Fields {
            selection = .JSON
            navigationTitleSize = .inline
            toolbarButtonString="Document"
            navigationBarTitle="JSON Object"
          } else {
            selection = .Fields
            navigationTitleSize = .large
            toolbarButtonString="JSON"
            navigationBarTitle="Document"
          }
        }
        .tint(Color("AccentColor"))
        .foregroundColor(Color("TextColor"))
      }
    }

    .toolbarBackground(.visible, for: .navigationBar)
    .navigationTitle(navigationBarTitle)
    .toolbarBackground(Color("TabBarColor"), for: .navigationBar)
    .navigationBarTitleDisplayMode(navigationTitleSize)
    #endif
  }
}
#endif
