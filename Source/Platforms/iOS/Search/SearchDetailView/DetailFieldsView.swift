// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import OrderedCollections


struct DetailFieldsView: View {
  
  @ObservedObject var itemDetail : DocumentDetail
  
  @Binding var presentedSheet: SearchSheet?
  
  var fields : [SquashedFieldsArray]
  
  @EnvironmentObject var filterObject : FilterObject
  @Environment(\.dismiss) private var dismiss
  @State var showNavigationBar = false
  
  @Binding var showDateInputView : DateQuery?
  
  var body: some View {
 
      VStack(alignment: .leading, spacing:0){
        
        ForEach(itemDetail.headers!, id: \.self) { item in
          
          VStack(spacing:0){
            let values = Results.getValueForKey(fieldParts: item.fieldParts,
                                                item:itemDetail.item!)
            
            ForEach(values, id: \.self) { output in
                            
              if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty  {
                
                HStack (alignment:.bottom, spacing:2){
                  Text(item.squashedString.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size:18, weight:.regular))
                    .foregroundColor(Color("LabelBackgroundFocus"))
                  
                  let fieldType = fields.first(where: {$0.fieldParts == item.fieldParts})?.type
                  if let fieldType = fieldType {
                    
                    Text(fieldType)
                      .font(.system(size:15))
                      .padding(.horizontal, 5)
                      .foregroundColor(Color("TextSecondary"))
                      .padding(.bottom, 2)
                  }
                }
                
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity, alignment:.leading)
                .padding(.horizontal, 18)
                
                HStack {
                  VStack(alignment: .leading, spacing:0) {
                    
                    Text(output.trimmingCharacters(in: .whitespacesAndNewlines))
                      .font(.system(size: 16))
                    
                    
                  }.foregroundColor(Color("TextColor"))
                    .padding(.vertical,15)
                  
                  Spacer()
                  
                  Button {
                    
                    let mappedField = fields.first(where: {$0.fieldParts == item.fieldParts})
                    
                    if let mappedField = mappedField,
                       mappedField.type == "date" {
                      // do a range check
                      
                      //                                    filterObject.absoluteRange = AbsoluteDateRangeObject()
                      
                      if let dateToQuery = DateTools.getDate(input: output){
                        showDateInputView=DateQuery(date:dateToQuery ,
                                                    field:item)
                      } else {
                        // todo
                        print("ERRORRRRRRR")
                      }
                      
                      
                    } else {
                      
                      let string = item.squashedString.trimmingCharacters(in: .whitespacesAndNewlines) + ":" +
                      output.trimmingCharacters(in: .whitespacesAndNewlines)
                      
                      if filterObject.query != nil {
                        filterObject.query?.values.append(QueryFilterObject(string: string))
                      } else {
                        filterObject.query = QueryObject()
                        filterObject.query?.values.append(QueryFilterObject(string: string))
                      }
                    }
                    
                    
#if os(iOS)
                    // this instantly pops to the home page
                    UINavigationBar.setAnimationsEnabled(false)
#endif
                    dismiss()
                    
                    // need to turn the animations back on
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
#if os(iOS)
                      UINavigationBar.setAnimationsEnabled(true)
#endif
                      presentedSheet = .query
                      
                    }
                  } label: {
                    Text(Image(systemName: "magnifyingglass"))
                      .font(.system(size: 18))
                      .padding(.vertical, 8)
                      .padding(.horizontal, 5)
                      .cornerRadius(5)
                      .foregroundColor(Color("TextSecondary"))
                  }
                }
                .padding(.horizontal, 15)
                .foregroundColor(Color("TextColor"))
                .frame(maxWidth: .infinity, alignment:.leading)
                .background(Color("BackgroundAlt"))
                .cornerRadius(5)
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
                
              }
            }
          }
          
        }
      }.padding(.top, 10)
    
    
#if os(iOS)
    .toolbar(showNavigationBar ? .visible : .hidden, for:.navigationBar)
#endif
    .onAppear {
      withAnimation(Animation.linear(duration:0)) {
        showNavigationBar = true
      }
    }
  }
}
