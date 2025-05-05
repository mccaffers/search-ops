// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchQuerySearchTermInput: View {
  
  @FocusState private var focusedField: Int?
  @State var selected : Int = 0
  @ObservedObject private var keyboard = KeyboardResponder()
  @State var value : [String] = [""]
  
  @EnvironmentObject var filterObject : FilterObject
  @Environment(\.dismiss) private var dismiss
  
  @State var compoundState = QueryCompoundEnum.must
  
  var body: some View {
    VStack(spacing:10) {
      
      VStack(alignment: .leading) {
        HStack (alignment:.bottom, spacing:5) {
          
          Text("Search Terms")
          
          Spacer()
          if value.count > 1 {
            Button {
              if compoundState == .must {
                compoundState = .should
              } else {
                compoundState = .must
              }
            } label: {
              Text(compoundState.rawValue)
                .padding(10)
                .background(Color("Button"))
                .cornerRadius(5)
                .foregroundColor(.white)
            }
            
            
          }
        }
        .font(.system(size: 18, weight:.regular))
        .foregroundColor(Color("TextColor"))
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 15)
      .padding(.top, 15)
      
      
      VStack(spacing:10) {
        
        ForEach(0 ..< value.count, id:\.self) { index in
          HStack {
            TextField("Term", text: $value[index], axis: .vertical)
              .focused($focusedField, equals: index)
            //                    .onChange(of: keyboard.willHide){ _ in
            //                        self.focusedField = .field
            //                    }
              .onChange(of: focusedField, perform: { newValue in
                // selected the textfield view, needs a negative check on selected
                // or swiftui loops forever
                
                //											selected.indices.forEach { selected[$0] = false }
                
                //
                //											if selected[index] != false && newValue == nil   {
                //												selected = index
                //											}
                //											if selected != index {
                //												selected = index
                //											}
              })
              .textFieldStyle(SelectedTextStyleWithoutBinding(focused: focusedField == index))
              .frame(maxWidth: .infinity)
            
            if value.count > 1 {
              Button {
                let target = index
                _ = withAnimation(Animation.linear(duration: 0.4)){
                  self.value.remove(at: target)
                }
              } label: {
                Image(systemName: "minus.circle")
                  .padding(10)
                  .background(Color("Button"))
                  .cornerRadius(5)
                  .foregroundColor(.white)
              }
              
            }
          }
          
          
        }
        
        Button {
          withAnimation(Animation.linear(duration: 0.4)){
            value.append("")
          }
          
          //														selected.append(false)
        } label: {
          Text("Add more terms")
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(Color("Button"))
            .cornerRadius(5)
        }
        
        
        
        Button {
          
          filterObject.query=nil
          for query in value {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
              continue
            }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if filterObject.query == nil {
              filterObject.query = QueryObject()
              filterObject.query?.values.append(QueryFilterObject(string:trimmed))
            } else {
              filterObject.query?.values.append(QueryFilterObject(string:trimmed))
            }
          }
          
          // Reset compound if we have less than 1
          if filterObject.query?.values.count ?? 0 > 1 {
            filterObject.query?.compound = compoundState
          } else {
            filterObject.query?.compound = .must
          }
          
          //
          //                    if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          //                        filterObject.query = [QueryFilterObject(string:value)]
          //                    } else {
          //                        filterObject.query = nil
          //                    }
          //
          dismiss()
        } label: {
          HStack {
            
            Text("Save")
            Text(Image(systemName: "square.and.arrow.down"))
          }
          .foregroundColor(.white)
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity)
          .background(Color("PositiveButton"))
          .cornerRadius(5)
        }
        
      }.padding(.horizontal, 15)
    }
    .onAppear {
      
      if let query = filterObject.query?.values.compactMap({$0.string}) {
        value = Array(query)
      }

    }
  }
}
