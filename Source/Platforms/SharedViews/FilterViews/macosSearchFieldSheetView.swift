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
  
  @Binding var updatedFieldsNotification : UUID
  @Binding var onlyVisibleFields : [SquashedFieldsArray]
  
  var showMapped = true
  
  @State var showingMeta = false
  
  @Binding var fieldsSearchtext : String

  @discardableResult
  public static func setFieldVisibility(
    item: SquashedFieldsArray,
    visible: Bool,
    fields: [SquashedFieldsArray],
    onlyVisibleFields: [SquashedFieldsArray]
  ) -> Bool {
    guard item.visible != visible else { return false }
    item.visible = visible
    onlyVisibleFields.first(where: { $0.squashedString == item.squashedString })?.visible = visible
    fields.first(where: { $0.squashedString == item.squashedString })?.visible = visible
    return true
  }
  
  func onHide(item: SquashedFieldsArray) {
    if Self.setFieldVisibility(item: item, visible: false, fields: fields, onlyVisibleFields: onlyVisibleFields) {
      updatedFieldsNotification = UUID()
    }
  }
  
  func onAdd(item: SquashedFieldsArray) {
    if Self.setFieldVisibility(item: item, visible: true, fields: fields, onlyVisibleFields: onlyVisibleFields) {
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
      .onChange(of: fields) { _ in
        loading = false
      }
      .onAppear {
        loading = false
      }
    
    
  }

}
