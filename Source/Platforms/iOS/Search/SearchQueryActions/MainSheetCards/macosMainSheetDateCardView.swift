// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosMainSheetDateCardView: View {
	
	
	@EnvironmentObject var filterObject : FilterObject
	@EnvironmentObject var selectedHost: HostDetailsWrap
	
	@Binding var selectedIndex : String
	
	var fields : [SquashedFieldsArray]
	
	@Binding var loading : String
	@State var showingHost = false
	
	func getMappedFields() async {
//		if let item = selectedHost.item,
//			 fields.count == 0 {
//			loading = "Requesting Mapping"
//			fields = await IndexMap.indexMappings(serverDetails: item, index: selectedIndex)
//			loading=""
//			
//		}
	}
	
  var body: some View {
    VStack(alignment: .leading, spacing:0){
      HStack (alignment:.top){
        
        HStack (alignment:.center){
          
          Text("Date Field")
            .font(.system(size: 26, weight:.bold))
          
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
      
      if selectedHost.item == nil || selectedIndex == "" {
        
        //				Text("Select an index")
        //					.padding(.vertical, 10)
        
      } else {
        
        HStack {
          if !loading.isEmpty {
            
            HStack (spacing:10) {
              ProgressView()
                .controlSize(.regular)
              Text(loading)
                .font(.system(size: 14))
            }.padding(.vertical, 10)
            
            
          } else {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                
                if fields.filter({$0.type == "date"}).count == 0 {
                  
                  HStack (spacing:2) {
                    Text("No date type in mapping")
                  }.padding(.vertical, 5)
                  
                } else if fields.filter({$0.type == "date"}).count > 5 {
                  
                  VStack (alignment:.leading, spacing:5) {
                    
                    Group {
                      if filterObject.dateField != nil {
                        VStack {
                          Text(filterObject.dateField?.index ?? "")
                            .font(.system(size:12))
                            .lineLimit(1)
                          Text(filterObject.dateField?.squashedString ?? "")
                            .frame(maxWidth:.infinity, alignment:.leading)
                        }.frame(alignment:.leading)
                      } else {
                        Text("Too many fields to render")
                      }
                    }.font(.system(size: 16))
                    
                  }.padding(.vertical, 5)
                } else {
                  
                  ForEach(fields, id: \.self) { item in
                    if item.type == "date" {
                      
                      Button {
                        //                                                if dateObj.field?.fieldParts == item.fieldParts {
                        //                                                    dateObj.valid = false
                        //                                                    dateObj.field = nil
                        //                                                } else {
                        //                                                    dateObj.index  = selectedHost.item?.name ?? "Index"
                        //                                                    dateObj.field = item
                        //                                                    dateObj.valid = true
                        //                                                }
                        
                        if filterObject.dateField == nil {
                          filterObject.dateField = item
                        } else {
                          filterObject.dateField = nil
                        }
                        
                        //                                        dateObj.field = item.squashedString
                      } label: {
                        VStack(
                          alignment: .leading,
                          spacing: 10
                        ) {
                          
                          Text(item.squashedString)
                          
                        }
                        .padding(10)
                        .foregroundColor(.white)
                        .background(filterObject.dateField?.fieldParts == item.fieldParts ? Color("ButtonHighlighted") : Color("Button"))
                        .cornerRadius(5)
                      }
                    }
                  }
                  
                }
              }
            }.fixedSize(horizontal: false, vertical: true)
              .padding(.vertical, 10)
          }
          
          Spacer()
          
          if fields.filter({$0.type == "date"}).count > 0 {
            Button {
              showingHost = true
            } label: {
              
              Text(Image(systemName: "chevron.right"))
                .font(.system(size: 22))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .foregroundColor(.white)
                .background(Color("ButtonExp"))
                .cornerRadius(5)
              
            }
          }
          
        }.frame(maxWidth: .infinity)
        
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 15)
    .background(Color("BackgroundAlt"))
    .cornerRadius(5)
    .padding(.horizontal, 10)
    .navigationDestination(isPresented:$showingHost, destination: {
      DateSheetListView(fields: fields,
                        localField: .constant(nil),
                        selectedIndex: selectedIndex)
    })
    .onChange(of: selectedIndex ) { newValue in
      
      filterObject.dateField = nil
      
//      if newValue != "" {
//        
//        Task {
//          await getMappedFields()
//        }
//        
//      } else {
//        fields = [SquashedFieldsArray]()
//      }
    }
    .onAppear {
      if selectedHost.item != nil &&
          selectedIndex != "" {
        Task {
          await getMappedFields()
        }
      } else {
        //                dateObj.ResetObj()
      }
    }
  }
}
