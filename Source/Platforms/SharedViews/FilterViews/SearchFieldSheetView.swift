// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchFieldSheetView: View {
  
//  @ObservedObject var resultsFields: RenderedFields
  @Binding var filteredFields: [SquashedFieldsArray]
  
  @Binding var updatedFieldsNotification : UUID
  var selectedIndex : String
  
  @State var filteredResults: [SquashedFieldsArray] = [SquashedFieldsArray]()
  @State var searchedFields: [SquashedFieldsArray] = [SquashedFieldsArray]()
  @State var searchedFilteredFields: [SquashedFieldsArray] = [SquashedFieldsArray]()
  @State var searchTerm = ""
  
  @ObservedObject private var keyboard = KeyboardResponder()
  @FocusState private var focusedField: FocusField?
  @State private var selected: Bool = false
  
  @EnvironmentObject var selectedHost: HostDetailsWrap
  @EnvironmentObject var filterObject: FilterObject
    
  @Binding var fields : [SquashedFieldsArray]
  
  @State var forceUIChange = UUID()
  
  @State var loading = false
  var horizontalPadding : CGFloat = 15
  
  @Environment(\.dismiss) private var dismiss
  
  func getMappedFields() async {
    if let item = selectedHost.item {
      if fields.count == 0 {
        loading=true
        fields = await IndexMap.indexMappings(serverDetails: item, index: selectedIndex)
        
        
        FilteredResults("")
        loading=false
      } else {
        searchTerm = ""
        refreshFilter()
      }
      
    }
  }
  
  func FilteredResults(_ term:String)  {
    
    if term.isEmpty {
      if fields.count > 1000 {
        searchedFields = [SquashedFieldsArray]()
      } else {
        searchedFields = fields
      }
      searchedFilteredFields = filteredFields
    } else {
      
      if (fields.count > 1000  && term.count >= 3) || fields.count <= 1000 {
        
        searchedFields=fields.filter({
          $0.squashedString
            .localizedLowercase
            .contains(term.localizedLowercase)
        })
        
      } else {
        searchedFields = [SquashedFieldsArray]()
      }
      
      searchedFilteredFields=filteredFields.filter({
        $0.squashedString
          .localizedLowercase
          .contains(term.localizedLowercase)
      })
    }
    
    
  }
  
  // After moving an item between the filtered and fields state
  // you need to refresh the view to make sure it isn't filtered
  // out of either array
  func refreshFilter() {
    FilteredResults(searchTerm)
  }
  
  func move(from source: IndexSet, to destination: Int) {
    filteredFields.move(fromOffsets: source, toOffset: destination)
    //        print(filteredFields)
  }
  
  var body: some View {
    NavigationStack {
      
      VStack (spacing:0) {
        
        if loading {
          VStack {
            VStack(spacing:20) {
              ProgressView()
                .controlSize(.large)
              Text("Requesting fields")
              
              HStack {
                Text(selectedHost.item?.name ?? "")
                  .padding(10)
                  .background(Color("InactiveButtonBackground"))
                  .cornerRadius(5)
                Text("/")
                Text(selectedIndex)
                  .padding(10)
                  .background(Color("InactiveButtonBackground"))
                  .cornerRadius(5)
                Text("/")
                Text("_mapping")
                  .padding(10)
                  .background(Color("InactiveButtonBackground"))
                  .cornerRadius(5)
              }
              
              Rectangle()
                .fill(.clear)
                .frame(height: 200)
              
            }
          }
          .frame(maxWidth: .infinity, maxHeight:.infinity)
          .background(Color("Background"))
        } else {
          
          HStack (spacing:5) {
            
            if filteredFields.count != 0 {
              Button {
                filteredFields = [SquashedFieldsArray]()
                fields.forEach( {$0.visible = false} )
                searchTerm = ""
              } label: {
                Text("Show all")
                  .padding(10)
                  .foregroundColor(.white)
                  .background(Color("Button"))
                  .cornerRadius(5)
              }.padding(.leading, 10)
            }
            
            TextField("Search", text: $searchTerm)
              .textFieldStyle(SelectedTextStyle(focused: $selected))
              .focused($focusedField, equals: .field)
#if os(iOS)
              .keyboardType(.alphabet)
              .textInputAutocapitalization(.none)
#endif
              .textContentType(.oneTimeCode)
              .autocorrectionDisabled(true)

              .onChange(of: searchTerm) { newValue in
                FilteredResults(newValue)
              }
              .padding(.horizontal, 10)
              .padding(.vertical, 10)
              .onAppear {
#if os(iOS)
                UITextField.appearance().clearButtonMode = .whileEditing
#endif
              }
            
            
          }
          
          List {
            
            if filteredFields.count > 0 {
              
              HStack {
                Text("Focused Fields")
                Spacer()
                Text(searchedFilteredFields.count.string)
              }
              .padding(.horizontal, 15)
              .listRowInsets(EdgeInsets())
              .listRowBackground(Color("BackgroundAlt"))
              
              ForEach(searchedFilteredFields.count == filteredFields.count ?
                      filteredFields : searchedFilteredFields, id: \.id) { item in
                
                VStack {
                  HStack(alignment: .center){
                    Text(Image(systemName: "line.3.horizontal"))
                      .font(.system(size: 24))
                      .foregroundColor(.gray)
                    
                    Button {
                      
                      filteredFields.removeAll(where: {$0.id == item.id})
                      fields.first(where: {$0.fieldParts == item.fieldParts})!.visible = false
                      refreshFilter()
                      
                    } label: {
                      HStack {
                      
                        Text(item.squashedString)
                          .padding(.vertical, 5)
                          .frame(maxWidth: .infinity, alignment:.leading)
                        
                        Spacer()
                        
                        Text(Image(systemName: "minus.square"))
                          .font(.system(size: 24))
                        
                        
                      }
                    }
                    
                  }
                  .padding(.leading, 10)
                  .padding(.trailing, 15)
                  //                            }
                }
              }
                      .onMove(perform: move)
                      .listRowInsets(EdgeInsets())
                      .listRowBackground(Color.clear)
            }
            
            HStack {
              Text("Fields")
              Spacer()
              if fields.count > 1000 && searchTerm.isEmpty {
                Text(fields.count.string)
              } else {
                Text(searchedFields.filter({!$0.visible}).count.string)
              }
            }
            .padding(.horizontal, 15)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color("BackgroundAlt"))
            
            if fields.count > 1000 {
              Text("There are more than 1,000 fields. Rendering could cause performance issues. You can still search for a field, start by typing the first three characters")
            }
            
            ForEach(searchedFields.sorted {$0.squashedString < $1.squashedString}, id: \.id) { item in
              
              if !item.visible &&
                  filterObject.dateField?.fieldParts != item.fieldParts  {
                
                VStack {
                  Button {
                    
                    if !item.visible {
                      item.visible = true
                      filteredFields.append(item)
                      refreshFilter()
                    }
                    
                  } label: {
                    VStack {
                      HStack {
                        Text(item.squashedString)
                          .padding(.vertical, 5)
                        
                        Spacer()
                        
                        
                        Text(Image(systemName: "plus.app"))
                          .font(.system(size: 24))
                        
                        
                      }
                    }
                    
                  }
                  .padding(.horizontal, 15)
                }
              }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
          }.listStyle(.plain)
        }
      }
      .background(Color("Background"))
      .onChange(of: keyboard.willHide){ _ in
        print("keyboard hidding")
        self.focusedField = .field
      }
      .onAppear {
        filteredFields.removeAll(where: {$0.fieldParts == filterObject.dateField?.fieldParts})
        fields.first(where: {$0.fieldParts == filterObject.dateField?.fieldParts})?.visible = false
      }
      .navigationTitle("Fields")
#if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            dismiss()
          }
        }
      }
#endif
      .id(forceUIChange)
    }
#if os(iOS)
    .onAppear {
      UINavigationBar.appearance() .backgroundColor = UIColor(Color("BackgroundAlt"))
    }
    .onDisappear {
      UINavigationBar.appearance().backgroundColor = UIColor(Color("Background"))
    }
#endif
    .onAppear {
      
      Task {
        _ = await getMappedFields()
      }
      
    }

  }
}

