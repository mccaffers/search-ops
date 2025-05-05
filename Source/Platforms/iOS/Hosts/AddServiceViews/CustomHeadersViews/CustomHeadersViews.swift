// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

struct CustomHeadersViews: View {
  
  func buttonPaddingTop(_ arraySize: Int) -> CGFloat {
    if arraySize > 0 {
      return CGFloat(0)
    } else {
      return CGFloat(0)
    }
    
  }
  
  @Binding var customHeadersArray : [LocalHeaders]
  @Binding var refresh : UUID
  
  @FocusState var focusedField: String?
  //    @Binding var item: HostDetails
  
  func reIndexCustomHeaders(){
    var index: Double = 0.0
    for header in customHeadersArray {
      header.focusedIndexHeader = index
      header.focusedIndexValue = index + 0.5
      index+=1
    }
  }
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 5
    ) {
      
      AddHostHeaderLabel(title:"Custom Headers")
      
      VStack(
        alignment: .leading,
        spacing: 10
      ) {
        
        
        ForEach($customHeadersArray, id:\.id) { index  in
          HStack {
            
            TextField("Header", text:  index.header)
              .focused($focusedField, equals: index.wrappedValue.focusedIndexHeader.string)
              .textFieldStyle(SelectedTextStyle(focused: .constant(false)))
#if os(iOS)
              .keyboardType(.alphabet)
              .textInputAutocapitalization(.never)
#endif
              .autocorrectionDisabled()
            
            TextField("Value", text:  index.value)
              .focused($focusedField, equals: index.wrappedValue.focusedIndexValue.string)
              .textFieldStyle(SelectedTextStyle(focused: .constant(false)))
#if os(iOS)
              .keyboardType(.alphabet)
              .textInputAutocapitalization(.never)
#endif
              .autocorrectionDisabled()
            
            Button(
              action: {
                customHeadersArray.removeAll{ $0.id == index.id.wrappedValue }
                reIndexCustomHeaders()
              }, label: {
                Image(systemName: "minus.circle")
              })
            
          }
          .padding(.horizontal, 20)
        }
        
        Button(action: {
          let newHeader = LocalHeaders()
          newHeader.focusedIndexHeader = Double(customHeadersArray.count)
          newHeader.focusedIndexValue = newHeader.focusedIndexHeader + 0.5
          customHeadersArray.append(newHeader)
          
        }) {
          Text("Add Header")
            .font(.system(size: 15))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height:40)
            .background(Color("Button"))
            .cornerRadius(5.0)
        }
        .padding(.horizontal, 20)
      }
    }
  }
}
