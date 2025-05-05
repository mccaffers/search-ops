// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosSearchFieldSheetView: View {
  
  @State var loading = false
  
  var selectedIndex: String

  @Binding var fields: [SquashedFieldsArray]

//  @EnvironmentObject var selectedHost: HostDetailsWrap
  @EnvironmentObject var filterObject: FilterObject
  
  @Binding var renderedObjects: RenderObject?
  @Binding var updatedFieldsNotification : UUID
  @Binding var onlyVisibleFields : [SquashedFieldsArray]
  
  var showMapped = true
  
  @State var showingMeta = false
  
  @Binding var fieldsSearchtext : String
  
  func onHide(item: SquashedFieldsArray) {
    if item.visible {
      item.visible = false
      updatedFieldsNotification = UUID()
    }
    
  }
  
  func onAdd(item: SquashedFieldsArray) {
    if !item.visible {
      item.visible = true
      updatedFieldsNotification = UUID()
    }
  }
  
  var filteredFields: [SquashedFieldsArray] {
    if showMapped {
      var output = fields.filter { $0.squashedString.contains(fieldsSearchtext) }
      
      if output.count == 0 {
        output = fields
      }
      return output
      
    } else {
      var output = onlyVisibleFields.filter { $0.squashedString.contains(fieldsSearchtext) }
      
      if output.count == 0 {
        output = onlyVisibleFields
      }
      
      output = fields.filter { item in
        output.contains(where: { $0.squashedString == item.squashedString})
      }
            
      return output
    }
  }
  
 

  var body: some View {
    
    VStack(alignment:.center, spacing: 0) {

        if loading {
          VStack {
            ProgressView()
            Spacer()
          }.frame(maxWidth: .infinity, alignment: .center)
        } else if filteredFields.count == 0 {
          Text("No visible fields")
            .padding(.top, 20)
            .foregroundStyle(Color("TextSecondary"))
          Spacer()
        } else {
          
          ScrollView {
            FieldsList(fields: filteredFields,
                       renderedObjects:  $renderedObjects,
                       onHide: onHide,
                       onAdd: onAdd)

          }.scrollIndicators(.never)
          
          Rectangle()
            .fill(Color("macosDivider"))
            .frame(height: 1)
            .padding(.top, 10)
          
    
          
        }
      }
      .onChange(of: selectedIndex) { newValue in
        loading = true
      }
      .onChange(of: fields) { newValue in
        fields.first { $0.fieldParts == filterObject.dateField?.fieldParts }?.visible = false
        loading = false
      }
      .onAppear {
        loading = true
        fields.first { $0.fieldParts == filterObject.dateField?.fieldParts }?.visible = false
        loading = false
      }
    
    
  }

}
