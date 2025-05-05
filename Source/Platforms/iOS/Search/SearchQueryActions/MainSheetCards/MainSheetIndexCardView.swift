// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct MainSheetIndexCardView: View {
  
  @EnvironmentObject var selectedHost: HostDetailsWrap
  @EnvironmentObject var serverObjects : HostsDataManager
  @State var showingHost : Bool = false
  @Binding var indexArray : [String]
  @Binding var selectedIndex : String
  
  @State var loading : Bool = false
  @State var responseError : ResponseError? = nil
  
  //    @EnvironmentObject var dateObj : DateRangeObj
  @EnvironmentObject var filterObject : FilterObject
  
  var changingIndex : () -> ()
  func UpdateIndexArray() async {
    loading = true
    let response = await Indicies.listIndexes(serverDetails: selectedHost.item!)
    
    if response.error != nil {
      responseError = response.error
    } else if let parsed = response.parsed {
      let serialisation = Results.getIndexArray(parsed)
      if let parsingError = serialisation.error {
        responseError = ResponseError(title: "Response Error", message: parsingError, type: .critical)
      } else {
        responseError = nil
        indexArray = serialisation.data
      }
      if indexArray.count == 0 {
        selectedIndex = ""
      }
    }
    
    
    loading = false
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing:0){
      HStack (alignment:.top){
        
        
        Text("Index")
          .font(.system(size: 26, weight:.bold))
        
        Spacer()
        
        if !loading && indexArray.count > 0 {
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
        
      }.frame(maxWidth: .infinity)  .padding(.bottom, 5)   .padding(.top, 5)
      
      if selectedHost.item == nil {
        Text("Select a host")
          .padding(.vertical, 10)
      } else if let error = responseError {
        VStack(alignment:.leading, spacing:10) {
          Text(error.title)
          Text(error.message)
        }
        .frame(maxWidth: .infinity, alignment:.leading)
        .padding(.vertical, 5)
      } else {
        
//        HStack {
          if !selectedIndex.isEmpty {
            Button {
              changingIndex()
              selectedIndex = ""
              filterObject.dateField = nil
              if indexArray.count == 0 {
                Task {
                  await UpdateIndexArray()
                }
              }
            } label: {
              
              Text(selectedIndex)
                .padding(10)
                .foregroundColor(.white)
                .background(Color("ButtonHighlighted"))
                .cornerRadius(5)
              
            }
            
          } else if loading {
            HStack (spacing:10) {
              ProgressView()
                .controlSize(.regular)
              Text("Loading Indices")
                .font(.system(size: 14))
            }.padding(.vertical, 10)
          } else if indexArray.count == 0 {
            // TODO
            // Check if connection failed
            // then only show this message
            // otherwise show _all ?
            Text("No indexes found")
              .padding(.vertical, 5)
          } else {
              WrappingHStack(horizontalSpacing: 5) {
                
                Button {
                  if selectedIndex == "_all" {
                    selectedIndex = ""
                  } else {
                    selectedIndex = "_all"
                  }
                  changingIndex()
                  //                                    dateObj.field = nil
//                  filterObject.dateField = nil
                } label: {
                  
                  Text("_all")
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color("Button"))
                    .cornerRadius(5)
                  
                }
                
                ForEach(indexArray.sorted(by: <).prefix(10), id: \.self) {  index in
                  Button {
                    if selectedIndex == index {
                      selectedIndex = ""
                    } else {
                      selectedIndex = index
                    }
                    changingIndex()
               
                    
                    //                                        dateObj.field = nil
                  } label: {
                    VStack(
                      alignment: .leading,
                      spacing: 10
                    ) {
                      Text("\(index)")
                      
                    }
                    .padding(10)
                    .foregroundColor(.white)
                    .background(selectedIndex == index ? Color("ButtonHighlighted") : Color("Button"))
                    .cornerRadius(5)
                  }
                
              }
            }
          }
          
          
          
          
//        }.frame(maxWidth: .infinity)
        
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 15)
    .background(Color("BackgroundAlt"))
    .cornerRadius(5)
    .padding(.horizontal, 10)
    .navigationDestination(isPresented:$showingHost, destination: {
      SearchHostIndexList(selectedIndex: $selectedIndex,
                          indexArray: $indexArray)
    })
    .onChange(of: selectedHost.item) { newValue in
      
      if newValue != nil {
        Task {
          await UpdateIndexArray()
        }
      } else {
        selectedIndex = ""
      }
    }
    .onAppear {
      
      // check if
      if selectedHost.item != nil && selectedIndex.isEmpty {
        Task {
          await UpdateIndexArray()
        }
      } else {
        //                selectedIndex = ""
      }
    }
  }
}
#endif
