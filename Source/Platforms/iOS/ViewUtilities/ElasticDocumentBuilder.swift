// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import OrderedCollections

import SwiftUI

enum TextDisplay {
  case highlighted
  case normal
  
}
public struct TextModel {
  var value: String
  var attributedString: AttributedString
  
  init(value: String, display: TextDisplay, valueFontSize: CGFloat = 12) {
    self.value = value
    // Initialize the attributed string based on the plain string
    self.attributedString = AttributedString(value)
    if display == .highlighted {
      self.attributedString.font = .system(size: 12, weight: .regular)
      self.attributedString.foregroundColor = Color("LabelBackgroundFocus")
    } else if display == .normal {
      self.attributedString.font = .system(size: valueFontSize, weight: .regular)
      self.attributedString.foregroundColor = Color("TextColor")
    }
    
  }
}

/// A utility class to build document representations for display.
public class ElasticDocumentBuilder {
  
  /// Constructs an array of SwiftUI `Text` views from specified input data and configuration.
  /// Each `Text` view is styled according to the provided headers and contains data extracted and formatted from the input.
  ///
  /// - Parameters:
  ///   - input: An `OrderedDictionary` where keys are string identifiers and values are the associated data, typically fetched from some data store.
  ///   - headers: An array of `SquashedFieldsArray`, which defines the fields to be extracted from `input` and how they are displayed.
  ///   - dateObj: An optional `SquashedFieldsArray` specifying a field to treat differently, typically used for date fields.
  /// - Returns: An array of `Text` views, each representing a formatted field from the input.
  public static func exportValues(input: OrderedDictionary<String, Any>,
                                  headers: [SquashedFieldsArray],
                                  dateObj: SquashedFieldsArray?,
                                  maxCount: Int = 300,
                                  valueFontSize: CGFloat = 16) -> [TextModel] {
    
    var myArray = [TextModel]()  // Array to hold the resulting Text views.
    var totalCount = 0           // Counter to limit the number of results.
    
    // Iterate over each header to process and format the data.
    for header in headers {
      // Extract the value associated with the current header's field parts from the input.
      let values = Results.getValueForKey(fieldParts: header.fieldParts,
                                          item: input)
      
      for output2 in values {
        
        
        // Skip processing if the extracted value is empty or contains only whitespace.
        if output2.isEmpty {
          continue
        }
        
        // Check if the current field is not the special date field.
        if header.fieldParts != dateObj?.fieldParts {
          
          var headerString = header.squashedString
          var valueString = output2
          
          if header.squashedString.count + totalCount > maxCount {
            var amountOfTextLeft = maxCount - totalCount
            if amountOfTextLeft > 0 {
              headerString = headerString.truncated(to: amountOfTextLeft)
              if !headerString.isEmpty {
                myArray.append(TextModel(value: headerString, display: .highlighted))
              }
            } else {
              return myArray
            }
          } else if !headerString.isEmpty {
            myArray.append(TextModel(value: headerString, display: .highlighted))
          }
          
          totalCount += header.squashedString.count
          
          if valueString.count + totalCount > maxCount {
            var amountOfTextLeft = maxCount - totalCount
            if amountOfTextLeft > 0 {
              if amountOfTextLeft <= 3 {
                valueString = valueString.truncated(to: amountOfTextLeft, addEllipsis: false) + "..."
              } else {
                valueString = valueString.truncated(to: amountOfTextLeft)
              }
              if !valueString.isEmpty {
                myArray.append(TextModel(value: valueString, display: .normal, valueFontSize: valueFontSize))
              }
            } else {
              return myArray
            }
          } else  if !valueString.isEmpty {
            myArray.append(TextModel(value: valueString, display: .normal, valueFontSize: valueFontSize))
          }
          
          totalCount +=  valueString.count
          
        }
        
        if totalCount > maxCount {
          return myArray
        }
        
      }
    }
      
      // Return the array containing all formatted Text views.
      return myArray
    
  }
  
  // Function to filter the OrderedDictionary based on filteredFields
  static func filterOrderedDictionary(input: OrderedDictionary<String, Any>, filteredFields: [SquashedFieldsArray]) -> OrderedDictionary<String, Any> {
      // Extract the squashedString values from filteredFields
      let allowedKeys = Set(filteredFields.map { $0.squashedString })
      
      // Filter the input OrderedDictionary
      let filteredInput = input.filter { allowedKeys.contains($0.key) }
      
      return OrderedDictionary(uniqueKeysWithValues: filteredInput)
  }
  
  
  public static func exportFlatValues(input: OrderedDictionary<String, Any>,
                                      filteredFields: [SquashedFieldsArray],
                                      maxCount: Int = 500,
                                      valueFontSize: CGFloat = 12) -> [TextModel] {
      var myArray = [TextModel]()
      var totalCount = 0
      var inputMap = input
    
      if filteredFields.count > 0 {
        inputMap = filterOrderedDictionary(input: inputMap, filteredFields: filteredFields)
      }
    
      for (header, value) in inputMap {
        guard let values = value as? [String], !values.isEmpty else { continue }
          
          for valueString in values {
              if valueString.trimmingCharacters(in: .whitespaces).isEmpty { continue }

              var headerString = header

              // Append header if within limits
              if totalCount + headerString.count > maxCount {
                  let amountOfTextLeft = maxCount - totalCount
                  if amountOfTextLeft > 0 {
                      headerString = headerString.truncated(to: amountOfTextLeft)
                      if !headerString.isEmpty {
                          myArray.append(TextModel(value: headerString, display: .highlighted))
                          totalCount += headerString.count
                      }
                  }
                  return myArray
              } else {
                  myArray.append(TextModel(value: headerString, display: .highlighted))
                  totalCount += headerString.count
              }

              // Append value if within limits
              var truncatedValueString = valueString
              if totalCount + truncatedValueString.count > maxCount {
                  let amountOfTextLeft = maxCount - totalCount
                  if amountOfTextLeft > 0 {
                      if amountOfTextLeft <= 3 {
                          truncatedValueString = truncatedValueString.truncated(to: amountOfTextLeft, addEllipsis: false) + "..."
                      } else {
                          truncatedValueString = truncatedValueString.truncated(to: amountOfTextLeft)
                      }
                      if !truncatedValueString.isEmpty {
                          myArray.append(TextModel(value: truncatedValueString, display: .normal, valueFontSize: valueFontSize))
                          totalCount += truncatedValueString.count
                      }
                  }
                  return myArray
              } else {
                  myArray.append(TextModel(value: truncatedValueString, display: .normal, valueFontSize: valueFontSize))
                  totalCount += truncatedValueString.count
              }

              // Exit if the limit is reached
              if totalCount >= maxCount {
                  return myArray
              }
          }
      }

      return myArray
  }

  
  public static func _exportFlatValues(input: OrderedDictionary<String, Any>,
                                      maxCount: Int = 300,
                                      valueFontSize: CGFloat = 16) -> [TextModel] {
    
    var myArray = [TextModel]()  // Array to hold the resulting Text views.
    var totalCount = 0           // Counter to limit the number of results.
    
    // Iterate over each header to process and format the data.
    for header in input.keys {
      // Extract the value associated with the current header's field parts from the input.
      let values = input[header] as! [String]
      
      for output2 in values {
        
        
        // Skip processing if the extracted value is empty or contains only whitespace.
        if output2.isEmpty {
          continue
        }
        
          var headerString = header
          var valueString = output2
          
        if headerString.count + totalCount > maxCount {
            var amountOfTextLeft = maxCount - totalCount
            if amountOfTextLeft > 0 {
              headerString = headerString.truncated(to: amountOfTextLeft)
              if !headerString.isEmpty {
                myArray.append(TextModel(value: headerString, display: .highlighted))
              }
            } else {
              return myArray
            }
          } else if !headerString.isEmpty {
            myArray.append(TextModel(value: headerString, display: .highlighted))
          }
          
          totalCount += headerString.count
          
          if valueString.count + totalCount > maxCount {
            var amountOfTextLeft = maxCount - totalCount
            if amountOfTextLeft > 0 {
              if amountOfTextLeft <= 3 {
                valueString = valueString.truncated(to: amountOfTextLeft, addEllipsis: false) + "..."
              } else {
                valueString = valueString.truncated(to: amountOfTextLeft)
              }
              if !valueString.isEmpty {
                myArray.append(TextModel(value: valueString, display: .normal, valueFontSize: valueFontSize))
              }
            } else {
              return myArray
            }
          } else  if !valueString.isEmpty {
            myArray.append(TextModel(value: valueString, display: .normal, valueFontSize: valueFontSize))
          }
          
          totalCount +=  valueString.count
          
        
        if totalCount > maxCount {
          return myArray
        }
        
      }
    }
      
      // Return the array containing all formatted Text views.
      return myArray
    
  }
}

