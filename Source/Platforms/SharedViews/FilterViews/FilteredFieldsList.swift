// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct FilteredFieldsList: View {
  @Binding var filteredFields: [SquashedFieldsArray]
  @Binding var searchedFilteredFields: [SquashedFieldsArray]
  var horizontalPadding : CGFloat = 15
  
  var onRemove: (SquashedFieldsArray) -> Void
  
  var body: some View {
    if filteredFields.count > 0 {
      HStack {
        Text("Focused Fields")
        Spacer()
        Text(searchedFilteredFields.count.string)
      }
      .padding(.horizontal, horizontalPadding)
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color("BackgroundAlt"))
      
      ForEach(searchedFilteredFields.count == filteredFields.count ? filteredFields : searchedFilteredFields, id: \.id) { item in
        VStack {
          HStack(alignment: .center) {
            Text(Image(systemName: "line.3.horizontal"))
              .font(.system(size: 24))
              .foregroundColor(.gray)
            
            Button {
              onRemove(item)
            } label: {
              HStack {
                Text(item.squashedString)
                  .padding(.vertical, 5)
                  .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text(Image(systemName: "minus.square"))
                  .font(.system(size: 24))
              }
            }
            .niceButton(
               foregroundColor: .white,
               backgroundColor: .clear,
               pressedColor: .clear
             )
          }
          .padding(.horizontal, horizontalPadding)
        }
      }
      .onMove(perform: move)
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color.clear)
    }
  }
  
  func move(from source: IndexSet, to destination: Int) {
    filteredFields.move(fromOffsets: source, toOffset: destination)
  }
}
