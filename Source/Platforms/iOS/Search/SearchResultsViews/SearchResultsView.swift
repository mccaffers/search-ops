// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import OrderedCollections

struct SearchResultsView: View {
  
  //    var searchResults : [[String: Any]]?
  var resultsFields:  RenderedFields
  @Binding var updatedFieldsNotification : UUID
  @Binding var renderedObjects : RenderObject?
  @Binding var filteredFields: [SquashedFieldsArray]
  @ObservedObject var itemDetail : DocumentDetail
  
  
  @State var setFrameHeight : Bool = false
  
  @EnvironmentObject var selectedHost: HostDetailsWrap
  @EnvironmentObject var filterObject : FilterObject
  
  var body: some View {
    
    VStack {
      
      if let renderedObjects = renderedObjects {
        
        ScrollView(.vertical, showsIndicators: true) {
          
          ScrollView(.horizontal, showsIndicators: false) {
            
            Grid(alignment: .leading,
                 horizontalSpacing: 0,
                 verticalSpacing: 0) {
              
              GridRow {
                
                if filterObject.dateField != nil {
                  Text(filterObject.dateField!.squashedString)
                    .foregroundColor(Color("LabelBackgroundBorder"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                  
                  Rectangle().fill(Color("GridBorder"))
                    .frame(width:2)
                  
                }
                
                ForEach(filteredFields.count > 0 ? filteredFields : renderedObjects.headers, id: \.self) { item in
                  
                  if filterObject.dateField?.fieldParts != item.fieldParts {
                    
                    Text(item.squashedString)
                      .foregroundColor(Color("LabelBackgroundBorder"))
                      .frame(maxWidth: .infinity, alignment: .leading)
                      .padding(.horizontal, 10)
                      .padding(.vertical, 10)
                      .onTapGesture {
                        print(item.squashedString)
                      }
                    
                    Rectangle().fill(Color("GridBorder"))
                      .frame(width:2)
                    
                  }
                  
                  
                }
              }
              .contentShape(Rectangle())
              .background(Color("BackgroundAlt"))
              .frame(maxHeight: 36)
              
              Rectangle().fill(Color("GridBorder"))
                .frame(maxWidth: .infinity)
                .frame(height:2)
              
              SearchResultsGridRow(renderedObjects: renderedObjects,
                                   itemDetail: itemDetail,
                                   filteredFields: $filteredFields)
              
              
            }
            
          }
          
          if filteredFields.count >= 1 {
            Text("Fields are being filtered by your selection. Documents will not be shown if they do not have any of the selected fields.")
              .padding(.horizontal, 10)
              .padding(.bottom, 5)
              .font(.system(size: 14))
          }
        }
        .padding(.top, 1)
        .onAppear {
#if os(iOS)
          // TODO
          // To investigate - wtf is going on here?
          if !setFrameHeight {
            let tableHeaderView = UIView(frame: .zero)
            tableHeaderView.frame.size.height = 1
            UITableView.appearance().tableHeaderView = tableHeaderView
            setFrameHeight = true
          }
#endif
        }
        .id(updatedFieldsNotification)
        .padding(.top, 0.1)
        
        
        
      } else if renderedObjects?.results.count == 0 {
        Spacer()
      } else {
        Spacer()
      }
    }
  }
}
