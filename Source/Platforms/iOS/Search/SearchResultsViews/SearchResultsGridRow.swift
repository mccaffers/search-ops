// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import OrderedCollections

struct SearchResultsGridRow: View {
  
  var renderedObjects : RenderObject
  
  @ObservedObject var itemDetail : DocumentDetail
  @State var highlightIndex : Int? = nil
  @Binding var filteredFields: [SquashedFieldsArray]
  @EnvironmentObject var filterObject : FilterObject
  
  var body: some View {
    
    
    // For each object
    ForEach(renderedObjects.results.indices, id: \.self) { index in
      
      let contentExists = Results.checkIfHeaderExistsInData(
        headers:filteredFields,
        item: renderedObjects.results[index])
      
      if contentExists {
        GridRow {
          
          
          
          if let squashedField = filterObject.dateField {
            
            let dateValue = Results.getValueForKey(fieldParts: squashedField.fieldParts,
                                                   item:renderedObjects.results[index])
            
            Text(dateValue.first ?? "")
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
            
            Rectangle().fill(Color("GridBorder"))
              .frame(width:2)
          }
          
          
          ForEach(filteredFields.count > 0 ?
                  filteredFields : renderedObjects.headers, id: \.self) { item in
            
            
            if filterObject.dateField?.fieldParts != item.fieldParts {
              
              let values = Results.getValueForKey(fieldParts: item.fieldParts,
                                                  item:renderedObjects.results[index])
              ForEach(values, id: \.self) { output in
                if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                  Text("No Value")
                    .italic()
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 10)
                } else {
                  
                  VStack {
                    
                    // TODO properly check if this is mapped as a date field not just look at the string
                    //                                    if item.squashedString == "date" {
                    //                                        Text(Utilities.buildDate(input: output))
                    //                                            .frame(maxWidth: .infinity,  alignment: .leading)
                    //
                    //                                    } else {
                    
                    Text(output.truncated(to: 100))
                      .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    //                                    }
                    
                  }
                  .padding(.horizontal, 10)
                  .padding(.vertical, 5)
                  
                }
              }
              
              
              Rectangle().fill(Color("GridBorder"))
                .frame(width:2)
            }
            
          }
        }
        .frame(maxHeight: 36)
        .contentShape(Rectangle())
        .background(highlightIndex == index ? Color("BackgroundAlt3") : nil)
        .onTapGesture {
          highlightIndex = index
          withAnimation(.linear(duration: 0.02)) {
            highlightIndex = nil
            
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            itemDetail.item = renderedObjects.results[index]
            itemDetail.headers = renderedObjects.headers
          }
          
        }
        
        Rectangle().fill(Color("GridBorder"))
          .frame(maxWidth: .infinity)
          .frame(height:2)
      }
    }
  }
}
