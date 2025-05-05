// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct SearchMainSheet: View {
  
  @Binding var selectedIndex: String
  @Binding var makeSearchRequest: Bool
  @Binding var fields : [SquashedFieldsArray]
  
  @Environment(\.dismiss) private var dismiss
  
  @Binding var loadingFields : String
  
  @Binding var indexArray : [String]
  @EnvironmentObject var orientation : Orientation
  @EnvironmentObject var filterObject: FilterObject
  @EnvironmentObject var selectedHost: HostDetailsWrap
  
  var changingIndex : () -> ()
  
  func getMappedFields() async {
    if let item = selectedHost.item,
       fields.count == 0 {
      loadingFields = "Requesting Mapping"
      fields = await IndexMap.indexMappings(serverDetails: item, index: selectedIndex)
      loadingFields=""
    }
  }
  
  var body: some View {
    NavigationStack {
      GeometryReader { reader in
        ScrollView {
          VStack(spacing:10) {
            
            MainSheetCardHostView()
            MainSheetIndexCardView(indexArray:$indexArray,
                                   selectedIndex:$selectedIndex,
                                   changingIndex: changingIndex)
            MainSheetDateCardView(selectedIndex: $selectedIndex,
                                  fields:$fields,
                                  loading:$loadingFields)
            if filterObject.dateField != nil {
              QueryDateCardView(selectedIndex: $selectedIndex)
            }
            MainSheetSortCardView(selectedIndex: $selectedIndex,
                                  fields:$fields,
                                  loading:$loadingFields)
            Spacer(minLength: 0)
            
            if !orientation.isLandscape {
              VStack {
                Image(systemName: "hand.draw")
                Text("Swipe down to close")
              }
              .frame(maxWidth: .infinity)
              .font(.footnote)
              .foregroundStyle(Color("TextSecondary"))
              .padding(.bottom, 10)
            }
            
          }.frame(minHeight: reader.size.height)
            .onChange(of: selectedIndex) { newValue in
              if !newValue.isEmpty {
                Task {
                  await getMappedFields()
                  let filteredFields = fields.filter({$0.type == "date"})
                  if filteredFields.count == 1,
                     let firstItem = filteredFields.first {
                    filterObject.dateField = firstItem
                  }
                }
              }
            }
            .onChange(of: filterObject.dateField) { newValue in
              if newValue != nil {
                if filterObject.relativeRange == nil {
                  filterObject.relativeRange = RelativeRangeFilter()
                }
                
                filterObject.relativeRange?.period = .Minutes
                filterObject.relativeRange?.value = 15
                
              } else {
                filterObject.relativeRange = nil
                filterObject.absoluteRange = nil
              }
            }
        }
      }
      .frame(maxHeight: .infinity)
      .background(Color("Background"))
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
      
      .navigationTitle("Hosts & Indices")
      .navigationBarTitleDisplayMode(.inline)

      .toolbar {
        if orientation.isLandscape {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              dismiss()
            } label: {
              Text("Close")
                .foregroundColor(Color("TextColor"))
            }
            
          }
        }
      }

    }
  }
}
#endif
