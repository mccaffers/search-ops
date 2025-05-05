// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosSearchDatePicker: View {
  
  @EnvironmentObject var filterObject : FilterObject
  @EnvironmentObject var selectedHost: HostDetailsWrap
  
  @Binding var selectedIndex : String
  
  @Binding var fields : [SquashedFieldsArray]
  
  @Binding var loading : String
  @State var showingHost = false
  @Binding var showingScreen : SideBarWrapper
  
  var clickedOpen = false
  var searchAction: () -> Void
  
  func getMappedFields() async {
    if let item = selectedHost.item,
       fields.count == 0 {
      loading = "Requesting Mapping"
//      fields = await IndexMap.indexMappings(serverDetails: item, index: selectedIndex)
      loading=""
      
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing:0){
      HStack (alignment:.top){
        
        
        Text("Date Field")
          .frame(maxWidth: .infinity,alignment: .leading)
        
        if filterObject.dateField != nil {
          Button {
            filterObject.dateField = nil
          } label: {
            VStack(
              alignment: .leading,
              spacing: 10
            ) {
              Text("Clear")
                .font(.system(size: 16))
            }
            
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
      
      if selectedHost.item != nil, selectedIndex != "" {
        
        
        if !loading.isEmpty {
          
          HStack (spacing:10) {
            ProgressView()
              .controlSize(.regular)
            Text(loading)
              .font(.system(size: 14))
          }.padding(.vertical, 10)
          
          
        } else {
          
          VStack {
            
            if fields.filter({$0.type == "date"}).count == 0 {
              
              HStack (spacing:2) {
                Text("No date type in mapping")
              }.padding(.vertical, 5)
              
            } else if filterObject.dateField != nil {
              List {
                Button {
                  filterObject.dateField = nil
                } label: {
                  Text(filterObject.dateField?.squashedString ?? "")
                }.niceButton(
                  foregroundColor: .white,
                  backgroundColor: .blue,
                  pressedColor: .clear
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
              }.listStyle(.plain)
                .frame(maxHeight: 40)
                .frame(maxWidth: .infinity,alignment: .leading)
              
            } else {
              List {
                
                ForEach(fields.filter { $0.type == "date"}, id: \.self) { item in
                  if item.type == "date" {
                    
                    Button {
                      
                      filterObject.dateField = item
                      filterObject.sort = SortObject(order: .Descending, field: item)
                      showingScreen = SideBarWrapper(item: .Fields)
                      searchAction()
                      
                      //                                        dateObj.field = item.squashedString
                    } label: {
                      
                      Text(item.squashedString)
                      
                      
                    } .niceButton(
                      foregroundColor: .white,
                      backgroundColor: .clear,
                      pressedColor: .clear
                    )
                  }
                }
                
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                
              }  .listStyle(.plain)
                .frame(maxWidth: .infinity,alignment: .leading)
              
              
            }
          }
        }
        
      }
    }
    .onAppear {
      
    
      
      if selectedHost.item != nil &&
          selectedIndex != "" {
        Task {
          await getMappedFields()
          
          if showingScreen.sender == .Flow,
             fields.filter({$0.type == "date"}).count == 0 {
            showingScreen = SideBarWrapper(item: .Fields)
            searchAction()
          }
          
        }
      } else {
        //                dateObj.ResetObj()
      }
    }

    .frame(maxWidth: .infinity,alignment: .leading)
    .onChange(of: selectedIndex ) { newValue in
      
      filterObject.dateField = nil

    }

  }
}
