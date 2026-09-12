// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHistoryButton: View {
  
  @ObservedObject var serverObjects: HostsDataManager
//  @StateObject var filterObject: FilterObject = FilterObject()
  
  var item : SearchEvent
  @Binding var firstSearchAfterSelectingIndex : Bool
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  var width : CGFloat
  var host: HostDetails
  var onDelete: (() -> ())? = nil

  @State private var isHovered: Bool = false
  @State private var isHoveringDelete: Bool = false

  private let deleteButtonWidth: CGFloat = 35

  var body: some View {
    let contentWidth = onDelete != nil ? max(width - deleteButtonWidth, 0) : width
    
    HStack(spacing: 0) {
      Button {
        if let historySelectedHost = serverObjects.items.first(where: {$0.id == item.host}) {
          
          var filterObject = FilterObject()
          filterObject.dateField = item.filter?.dateField
          if let relativeRange = item.filter?.relativeRange {
            filterObject.relativeRange = relativeRange
          }
          if let absoluteRange = item.filter?.absoluteRange {
            filterObject.absoluteRange = absoluteRange
          }
          filterObject.query = item.filter?.query
          //      firstSearchAfterSelectingIndex = false
          
          request(historySelectedHost, item.index, filterObject)
        }
        
      } label: {
        macosSearchHistoryButtonLabel(item: item, selectedHost: host, width: contentWidth)
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())

      if let onDelete = onDelete {
        Button {
          onDelete()
        } label: {
          ZStack {
            Rectangle()
              .fill(Color.clear)
              .frame(width: deleteButtonWidth)
            Image(systemName: "xmark")
              .font(.system(size: 11, weight: .semibold))
              .foregroundColor(isHoveringDelete ? Color("RedIcon") : (isHovered ? Color("TextSecondary") : Color("TextSecondary").opacity(0.6)))
          }
          .padding(.vertical, 4)
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isHoveringDelete = hovering
        }
        .help("Delete recent search")
      }
    }
    .background(Color("BackgroundAlt").opacity(isHovered ? 1 : 0.65))
    .onHover { hovering in
      isHovered = hovering
    }
  }
}
