// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHistoryButtonLabel: View {
  
  var item : SearchEvent
  var selectedHost: HostDetails
  var width : CGFloat
  
  var labelTextColor = Color("macosHomeLabels")

  /// One line per filter, eg. "hostname: live-trading" or "NOT env: demo", with "(off)" for disabled ones.
  static func filtersHelp(_ filters: [FieldFilter]) -> String {
    filters.map { filter in
      "\(filter.negated ? "NOT " : "")\(filter.field): \(filter.value)\(filter.disabled ? " (off)" : "")"
    }
    .joined(separator: "\n")
  }

  var body: some View {
    VStack (spacing:0){
      
        HStack(spacing:0) {
          
          HStack(spacing:0){
            Text(selectedHost.name)
              .padding(.leading, 5)
          }
            .frame(width: width*0.15, alignment:.leading)
          
          
          Text(item.index)
            .frame(width: width*0.15, alignment:.leading)
          
          
          HStack(spacing: 6) {
            Text(item.filter?.query?.values.first?.string ?? "*")
              .lineLimit(1)
              .truncationMode(.tail)
            
            if let fieldFilters = item.filter?.fieldFilters, !fieldFilters.isEmpty {
              Text("· \(fieldFilters.count) \(fieldFilters.count == 1 ? "filter" : "filters")")
                .font(.system(size: 12))
                .foregroundColor(Color("TextSecondary"))
                .fixedSize()
                .help(macosSearchHistoryButtonLabel.filtersHelp(fieldFilters))
            }
          }
          .frame(width: width*0.4, alignment:.leading)
          
          if let dateField = item.filter?.dateField {
            if let relativeRange = item.filter?.relativeRange {
              Text(relativeRange.GeneratePrettyTimeString())
                .font(.system(size: 12))
                .frame(width: width*0.3, alignment:.leading)
            } else if let absoluteRange = item.filter?.absoluteRange {
              Text(absoluteRange.generatePrettyString())
                .font(.system(size: 12))
                .frame(width: width*0.3, alignment:.leading)
            }
          } else {
            Text("None")
              .italic()
              .frame(width: width*0.3, alignment:.leading)
          }
          
        }      
        .frame(width: width, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())

    }

  }
}
