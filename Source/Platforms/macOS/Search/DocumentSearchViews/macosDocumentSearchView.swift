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
  var showDateHeader: Bool
  
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
  
  func processRow(item: OrderedDictionary<String, Any>, dateField: SquashedFieldsArray?) -> (item: OrderedDictionary<String, Any>, myDic: [TextModel], dateValue: String, shouldShowRow: Bool) {
    var itemWithoutDate = item
    if let dateKey = dateField?.squashedString {
      itemWithoutDate.removeValue(forKey: dateKey)
    }
    let myDic = ElasticDocumentBuilder.exportFlatValues(input: itemWithoutDate, filteredFields: filteredFields)
    let dateValue = getDateValue(from: item)
    let shouldShow = Self.shouldDisplayRow(
      hasBodyContent: !myDic.isEmpty,
      showDateHeader: showDateHeader,
      hasDateValue: !dateValue.isEmpty,
      isBodyFiltered: !filteredFields.isEmpty
    )
    return (item, myDic, dateValue, shouldShow)
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
                let row = processRow(item: flatArray[index], dateField: renderedObjects.dateField)
                
                if row.shouldShowRow {
                  macosGridRowView(
                    itemDetail: itemDetail,
                    item: row.item,
                    dateField: showDateHeader ? buildDateObject(from: renderedObjects.dateField, dateValue: row.dateValue) : nil,
                    textArray: row.myDic.map { Text($0.attributedString + " ") }.reduce(Text(""), +)
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

extension macOSDocumentSearchView {
  /// Determines whether a document row should be rendered in the search results.
  /// When body fields are filtered (`isBodyFiltered == true`), documents must contain at least one of the selected
  /// body fields (`hasBodyContent == true`) to prevent rendering ghost cards with only a date header.
  /// When body fields are unfiltered (`isBodyFiltered == false`), documents are displayed if they have body content
  /// or an active date header with a valid date.
  public static func shouldDisplayRow(
    hasBodyContent: Bool,
    showDateHeader: Bool,
    hasDateValue: Bool,
    isBodyFiltered: Bool
  ) -> Bool {
    isBodyFiltered
      ? hasBodyContent
      : (hasBodyContent || (showDateHeader && hasDateValue))
  }
}
