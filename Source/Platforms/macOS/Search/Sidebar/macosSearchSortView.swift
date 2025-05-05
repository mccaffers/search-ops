// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosSearchSortView: View {
  
  @EnvironmentObject var filterObject : FilterObject
  @EnvironmentObject var selectedHost: HostDetailsWrap
  
  @Binding var selectedIndex : String
  
  @Binding var fields : [SquashedFieldsArray]
  
  @State var showingHost = false
  @State var sortField : SquashedFieldsArray? = SquashedFieldsArray()
  
  @State var sortOrder : SortOrderEnum = .Descending
  
  @Binding var loading : String
  
  func getSortFieldLabel() -> String {
    var sortLabel = "Select a field"
    if let squashedString = filterObject.sort?.field.squashedString {
      sortLabel = squashedString
    }
    return sortLabel
  }

  var body: some View {
    VStack(alignment: .leading, spacing:0){
      HStack (alignment:.top){
        
        HStack (alignment:.center){
          Text("Sort")
            .frame(maxWidth: .infinity,alignment: .leading)
          if let queryObj = filterObject.sort {
            Button {
              filterObject.sort = nil
              sortField = nil
            } label: {
              VStack(
                alignment: .leading,
                spacing: 10
              ) {
                Text("Clear")
                  .font(.system(size: 16))
              }
              .padding(.vertical, 8)
              .padding(.horizontal, 10)
              .foregroundColor(.white)
              .background(Color("WarnButton"))
              .cornerRadius(5)
            }
          } else {
            HStack(spacing:3) {
              Text("Not Set")
            }
            .padding(8)
            .foregroundColor(Color("TextColor"))
            .background(Color("LabelBackgrounds"))
            .cornerRadius(5)
          }
        }
        
        
        Spacer()
        
        Text("Optional")
          .font(.system(size: 14))
          .foregroundColor(Color("TextSecondary"))
        
      }
      .frame(maxWidth: .infinity)
      .padding(.bottom, 5)
      .padding(.top, 5)
      
      
      
      if selectedHost.item == nil || selectedIndex.isEmpty {
        
//        Text("Select an index")
//          .padding(.vertical, 10)
//
      } else   if !loading.isEmpty {
        
        HStack (spacing:10) {
          ProgressView()
            .controlSize(.regular)
          Text(loading)
            .font(.system(size: 14))
        }.padding(.vertical, 10)
        
      } else {
        
        Text("Defaults to the Date Field, if selected")
          .font(.system(size: 14))
          .foregroundColor(Color("TextSecondary"))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 10)
          .animation(.easeIn, value: 1)
        
        List {
          
          HStack {
            VStack (spacing:5) {
              Text("Field")
              
              Button  {
                showingHost = true
              } label: {
                
                Text(getSortFieldLabel())
              }
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            VStack (alignment:.leading, spacing:5) {
              
              Text("Order")
              
              Button  {
                if sortOrder == .Ascending {
                  sortOrder = .Descending
                } else {
                  sortOrder = .Ascending
                }
                
                if let sortField = sortField {
                  filterObject.sort = SortObject(order: sortOrder, field: sortField)
                }
                
              } label: {
                Text(sortOrder.rawValue)
              }
            }
          }.padding(.top, 5)
          
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
          
          
        }  .listStyle(.plain)
          .frame(maxWidth: .infinity,alignment: .leading)
          .frame(maxHeight: 40)
        
        
       
      }
    
    }
    .navigationDestination(isPresented:$showingHost, destination: {
      DateSheetListView(fields: fields,
                        localField: $sortField,
                        showAllObjects:true,
                        usingLocalField:true)
    })
    .onChange(of: selectedIndex) { newValue in
        filterObject.sort = nil
    }
    .onChange(of: sortField) { newValue in
      if let newValue = newValue {
        filterObject.sort = SortObject(order: sortOrder, field: newValue)
      } else {
        filterObject.sort = nil
      }
    }
    .onChange(of: filterObject.dateField) { newValue in
      
      // align with date field, but don't remove sort if it's empty
      if newValue != nil {
        sortField = newValue
      }
//      filterObject.sort = SortObject(order: sortOrder, field: newValue)
    }
    .frame(maxWidth: .infinity,alignment: .leading)

  }
}
