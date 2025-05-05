// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

import OrderedCollections

struct macosGridRowView: View {
  
  @ObservedObject var itemDetail : DocumentDetail
  var item: OrderedDictionary<String, Any>
  let dateField: (key: SquashedFieldsArray, value: String)?
  let textArray : Text
  
  func buildAttr(input: String, color: Color? = nil) -> AttributedString {
    var result = AttributedString(input)
    result.font = .system(size: 12, weight: .regular)
    
    if let color = color {
      result.foregroundColor = color
    }
    
    return result
  }
  
  var body: some View {
    HStack (spacing:0){
      
      VStack (alignment:.leading) {
        
        HStack (alignment:.top){
          
          VStack {
            if let dateField = dateField {
              
              VStack(alignment: .leading) {
                HStack {
                  Text(buildAttr(input: dateField.key.squashedString, color: Color("LabelBackgroundFocus")))
                  + Text(" ")
                  + Text(buildAttr(input: DateTools.buildDateLarge(input: dateField.value)))
                }
                .foregroundColor(Color("TextColor"))
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
            
            
            
            textArray
              .frame(maxWidth: .infinity, alignment:.leading)
              .lineSpacing(3)
          }
          .padding(10)
          
          
          .frame(maxWidth: .infinity)
          .multilineTextAlignment(.leading)
          VStack {
            Button {
              
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                itemDetail.item = item
              }
//              selection = .SearchDocumentView
              
            } label: {
              Image(systemName: "info")
                .padding(12)
                .background(Color("Button"))
                .clipShape(.rect(
                  topLeadingRadius: 0,
                  bottomLeadingRadius: 5,
                  bottomTrailingRadius: 0,
                  topTrailingRadius: 0
                )
                )
            }.buttonStyle(PlainButtonStyle())
          }
        
        }
        
        
      }
      .textSelection(.enabled)
      .background(Color("BackgroundAlt"))
      .cornerRadius(5)
 
    }
//    .padding(.trailing, 10)
    .padding(.bottom, 5)
  }
}
