// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SimpleSearchResultsView: View {
  
  @Binding var renderedObjects : RenderObject?
  @ObservedObject var resultsFields:  RenderedFields
  @ObservedObject var itemDetail : DocumentDetail
  @Binding var filteredFields: [SquashedFieldsArray]
  
  @EnvironmentObject var filterObject : FilterObject
  
  var gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]
  @State var highlightIndex : Int? = nil
  
  var horizontalPadding : CGFloat = 8
  var valueFontsize : CGFloat = 16
  
  var body: some View {
    VStack {
      
      if let renderedObjects = renderedObjects {
        
        ScrollView(.vertical, showsIndicators: true) {
          
          Grid(alignment: .leading,
               horizontalSpacing: 0,
               verticalSpacing: 0) {
            
            ForEach(renderedObjects.results.indices, id: \.self) { index in
              
              let myDic = ElasticDocumentBuilder.exportValues(
                input: renderedObjects.results[index],
                headers: filteredFields.count == 0 ? renderedObjects.headers : filteredFields,
                dateObj: filterObject.dateField,
                valueFontSize: valueFontsize)
              
              if myDic.count > 0 {
                
                GridRow {
                  
                  
                  VStack(alignment: .leading, spacing:0){
                    
                    
                    VStack (alignment:.leading) {
                      if filterObject.dateField != nil {
                        
                        let output = Results.exportDate(
                          dateField: filterObject.dateField?.fieldParts ?? [""],
                          input: renderedObjects.results[index])
                        
                        if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                          
                          var message: AttributedString {
                            // TODO this might need a check
                            // not sure we want an empty field popping up here
                            var result = AttributedString(filterObject.dateField?.squashedString ?? "")
                            result.font = .system(size: 14, weight:.regular)
                            result.foregroundColor = Color("LabelBackgroundFocus")
                            
                            return result
                          }
                          
                          var date: AttributedString {
                            var result = AttributedString(DateTools.buildDateLarge(input: output))
                            result.font = .system(size: valueFontsize, weight:.regular)
                            
                            return result
                          }
                          
                          VStack(alignment: .leading){
                            Group {
                              Text(message + " ") + Text(date)
                            }
                            
                          }
                          .foregroundColor(Color("TextColor"))
                          .padding(.bottom, 5)
                          .frame(maxWidth: .infinity, alignment: .leading)
                          
                        }
                      }
                      
                      
                      
                      
                      var textArray = myDic.map { Text("\($0.attributedString) ") }.reduce(Text(""), +)
                        .frame(maxWidth: .infinity, alignment:.leading)
                      
                      
                      VStack {
                        textArray
                          .lineSpacing(5)
                        
                      }
                      
                      .frame(maxWidth: .infinity)
                      .multilineTextAlignment(.leading)
                      
                      
                      
                      
                    }
                    .padding(15)
                    .background(highlightIndex == index ? Color("BackgroundAlt3") : Color("BackgroundAlt"))
                    .cornerRadius(5)
                    
                  }
                  
                  .padding(.bottom, 5)
                  .padding(.horizontal, horizontalPadding)
                  
                  
                  
                }
                .frame(maxWidth: .infinity)
                
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
                
              }
            }
            
          }
          
          if filteredFields.count >= 1 {
            Text("Fields are being filtered by your selection. Documents will not be shown if they do not have any of the selected fields.")
            
              .padding(.horizontal, 10)
              .font(.system(size: 14))
          }
        }
        .padding(.top, 1)
      } else {
        Spacer()
      }
    }
    .padding(.top, 0.1)
    
  }
}
