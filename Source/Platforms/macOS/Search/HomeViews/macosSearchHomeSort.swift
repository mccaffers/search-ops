// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeSort: View {
  
  @Binding var fields : [SquashedFieldsArray]
  @ObservedObject var localFilterObject: FilterObject
  @State var hoveringActiveButton : Bool = false
  @Binding var selection: macosSearchViewEnum
  
  @State var refreshOrderButton = UUID()
  
  var maxFieldCount = 15
  
  var body: some View {
    VStack (alignment:.leading, spacing:5){
      
      HStack {
        Text("Sort By")
          .font(.subheadline)
          .foregroundStyle(Color("TextSecondary"))
      }
      
      if fields.count == 0 {
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
      } else if localFilterObject.sort != nil {
        

        HStack {
          HStack {
            Button(action: {
              localFilterObject.sort = nil
            }) {
              Text(localFilterObject.sort?.field.squashedString ?? "")
                .padding(10)
                .background(Color("Background"))
                .clipShape(.rect(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hover in
              hoveringActiveButton = hover
            }

            Image(systemName: "xmark.circle")
              .bold()
              .padding(.leading, -16)
              .padding(.top, -25)
              .hiddenConditionally(isHidden: !hoveringActiveButton)
            
          }
          .padding(.trailing, -11)
          if let sorted = localFilterObject.sort  {
            Button(action: {
              if sorted.order == .Ascending {
                localFilterObject.sort?.order = .Descending
              } else {
                localFilterObject.sort?.order = .Ascending
              }
              refreshOrderButton=UUID()
            }) {
              Text(sorted.order.rawValue)
                .padding(10)
                .background(Color("Background"))
                .clipShape(.rect(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .id(refreshOrderButton)
          }
         
        }
      } else {
        

        Button {
          selection = .NewSearchFieldPicker
        } label: {
          HStack(spacing:5) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
              .font(.system(size: 13))
              .scaleEffect(x: -1, y: 1)
            Text("Show fields list")
          }
          .padding(10)
          .background(Color("Background"))
          .clipShape(.rect(cornerRadius: 5))
        }
        .buttonStyle(PlainButtonStyle())
        
      }
      
      
    }
    .onChange(of: localFilterObject.dateField ?? SquashedFieldsArray()) { newValue in
      if !newValue.squashedString.isEmpty {
        localFilterObject.sort = SortObject(order: .Descending, field: newValue)
      }
    }
  }
}
