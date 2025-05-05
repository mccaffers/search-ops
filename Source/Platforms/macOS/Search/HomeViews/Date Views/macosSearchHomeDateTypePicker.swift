// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI


struct macosSearchHomeDateTypePicker: View {
  @ObservedObject var localFilterObject: FilterObject
  @Binding var selection: macosSearchViewEnum
  @Binding var fields : [SquashedFieldsArray]
  @Binding var loadingFieldsMapping : Bool
  
  var filteredFields : [SquashedFieldsArray] {
    fields.filter { $0.type == "date"}
  }
  
  @State var hoveringActiveButton = false
  @State var haveSetDataInitially = false // stop it overriding if you cancel the date field

  
  var body: some View {
    VStack (alignment:.leading) {
      HStack (alignment:.top){
        VStack (alignment: .leading, spacing:5){
          Text("Date Fields")
            .font(.subheadline)
            .foregroundStyle(Color("TextSecondary"))
          
          
          if loadingFieldsMapping {
            HStack {
              ProgressView()
                .scaleEffect(0.7)
                .padding(5)
              Text("Loading Mapping Values")
                .font(.subheadline)
                .padding(10)
              Spacer()
            }
          } else if filteredFields.count == 0 {
            HStack (spacing:5) {
              RoundedRectangle(cornerRadius: 5)
                .fill(Color("Background"))
                .frame(width: 120)
                .frame(height: 35)
              
              RoundedRectangle(cornerRadius: 5)
                .fill(Color("Background"))
                .frame(width: 85)
                .frame(height: 35)
              
              RoundedRectangle(cornerRadius: 5)
                .fill(Color("Background"))
                .frame(width: 50)
                .frame(height: 35)
              
            }.frame(maxWidth: .infinity, alignment: .leading)
          } else if localFilterObject.dateField != nil {
            HStack {
              Button {
                localFilterObject.dateField = nil
              } label: {
                Text(localFilterObject.dateField?.squashedString ?? "")
                  .padding(10)
                  .background(Color("Background"))
                  .clipShape(.rect(cornerRadius: 5))
              }.buttonStyle(PlainButtonStyle())
                .onHover { hover in
                  hoveringActiveButton = hover
                }
              //              if hoveringActiveButton {
              Image(systemName: "xmark.circle")
                .bold()
                .padding(.leading, -16)
                .padding(.top, -25)
                .hiddenConditionally(isHidden: !hoveringActiveButton)
              //              }
            }
            
          } else {
            WrappingHStack(horizontalSpacing: 5) {
              ForEach(filteredFields, id: \.self) { item in
                Button {
                  if localFilterObject.dateField == item {
                    localFilterObject.dateField = nil
                  } else {
                    withAnimation {
                      localFilterObject.dateField = item
                    }
                    localFilterObject.relativeRange = nil
                    localFilterObject.absoluteRange = nil
                  }
                } label: {
                  Text(item.squashedString)
                    .padding(10)
                    .background(localFilterObject.dateField == item ? Color("Background") : Color("Button"))
                    .clipShape(.rect(cornerRadius: 5))
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .onAppear {
              if filteredFields.count == 1,
                 let firstDateField = filteredFields.first ,
                 !haveSetDataInitially {
                withAnimation {
                  localFilterObject.dateField = firstDateField
                }
                haveSetDataInitially = true
                localFilterObject.relativeRange = nil
                localFilterObject.absoluteRange = nil
              }
            }
          }
          
        }
        
        
        
      }
      
      
    }
  }
}
    
