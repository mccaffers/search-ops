// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

import OrderedCollections

struct macOSDocumentSearchView: View {
  
  @Binding var renderedObjects: RenderObject?
  @ObservedObject var resultsFields: RenderedFields
  @ObservedObject var itemDetail: DocumentDetail
  
  var filteredFields: [SquashedFieldsArray]
  
  var gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]
  
  func getDateValue(from flatArray: OrderedDictionary<String, Any>) -> String {
    guard let dateField = renderedObjects?.dateField else { return "" }
    if let output = flatArray.first(where: { $0.key == dateField.squashedString })?.value as? [String], !output.isEmpty {
      return output.first ?? ""
    }
    return ""
  }
  
  func buildDateObject(from dateField: SquashedFieldsArray?, dateValue: String) -> (key: SquashedFieldsArray, value: String)? {
    guard let dateField = dateField, !dateValue.isEmpty else { return nil }
    return (key: dateField, value: dateValue)
  }
  
  
  var body: some View {
    VStack {
      if let renderedObjects = renderedObjects {
        ScrollView(.vertical, showsIndicators: false) {
          Grid(alignment: .leading,
               horizontalSpacing: 0,
               verticalSpacing: 0) {
            if let flatArray = renderedObjects.flat {
              ForEach(flatArray.indices, id: \.self) { index in
                let item = flatArray[index]
                let myDic = ElasticDocumentBuilder.exportFlatValues(input: item, filteredFields: filteredFields)
                let dateValue = getDateValue(from: flatArray[index])
                
                if !myDic.isEmpty {
                  macosGridRowView(
                    itemDetail: itemDetail,
                    item:item,
                    dateField: buildDateObject(from: renderedObjects.dateField, dateValue: dateValue),
                    textArray: myDic.map { Text($0.attributedString + " ") }.reduce(Text(""), +)
                  )
                }
              }
            }
          }
          if !filteredFields.isEmpty {
            Text("Fields are being filtered by your selection. Documents will not be shown if they do not have any of the selected fields.")
              .padding(.horizontal, 10)
              .font(.system(size: 14))
          }
        }
        
      } else {
        Spacer()
      }
    }
    .padding(.top, 0.1)
  }
}
