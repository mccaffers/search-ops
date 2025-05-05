// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosDatePickerFieldsView: View {
  @EnvironmentObject var filterObject: FilterObject
  @Binding var selection: macosSearchViewEnum
  @Binding var fields : [SquashedFieldsArray]
  @Binding var showingMappedDateFields : Bool
  
  var filteredFields : [SquashedFieldsArray] {
    fields.filter { $0.type == "date"}
  }
  
    var body: some View {
      VStack {
        VStack {
          HStack {
            Text("Fields with Date type")
              .font(.system(size: 15))
              .bold()
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, 10)
            
            if filterObject.dateField != nil {
              Button {
                filterObject.dateField = nil
                filterObject.relativeRange = nil
                filterObject.absoluteRange = nil
                selection = .None
              } label: {
                Text("Clear")
                  .padding(10)
                  .background(Color("WarnText"))
                  .clipShape(.rect(cornerRadius: 5))
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
          if filteredFields.count == 0 {
            VStack(alignment:.leading, spacing:10) {
              Text("No date fields found")
                .frame(maxWidth: .infinity, alignment: .leading)
              Text("You can only apply date ranges if your data contains a date field")
                .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.bottom, 10)
          } else {
            ScrollView {
              ForEach(filteredFields, id: \.self) { item in
                Button {
                  filterObject.dateField = item
                  showingMappedDateFields = false
                } label: {
                  Text(item.squashedString)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color("BackgroundAlt"))
                    .clipShape(.rect(cornerRadius: 5))
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .frame(maxHeight: 300)
          }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color("Button"))
        .clipShape(.rect(cornerRadius: 5))
        .padding(10)
      }
    }
}

