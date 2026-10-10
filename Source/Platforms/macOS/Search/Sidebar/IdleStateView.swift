// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosIndiceList: View {
  @Binding var selectedIndex: String
  var indexArray: [String]
  var dataViews: [DataView] = []
  var selectedDataView: DataView? = nil
  var dataViewAction: (DataView) -> Void = { _ in }
  var showAll: Bool = true
  var searchAction: () -> Void
  var hideAction: () -> ()
  
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        if !dataViews.isEmpty {
          macosDropdownGroupHeading(title: "Data views")
          ForEach(dataViews) { view in
            macosDropdownDataViewButton(view: view,
                                        isSelected: view.id == selectedDataView?.id,
                                        action: { dataViewAction(view) })
            .padding(.horizontal, 5)
          }
          macosDropdownGroupHeading(title: "Indices")
        }

        if showAll {
          macosDropdownIndiciesButton(selectedIndex: $selectedIndex,
                                      sortedIndex: "_all",
                                      searchAction: searchAction,
                                      hideAction: hideAction)
          .padding(.horizontal, 5)
        }
        
        let sortedIndex = indexArray.sorted(by: <)
        ForEach(sortedIndex, id: \.self) { indexName in
          macosDropdownIndiciesButton(selectedIndex: $selectedIndex,
                                      sortedIndex: indexName, 
                                      searchAction: searchAction,
                                      hideAction: hideAction)
          .padding(.horizontal, 5)
        }
        
        if !showAll && indexArray.isEmpty {
          HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(Color("TextSecondary"))
            Text("No matching indices")
              .foregroundColor(Color("TextSecondary"))
              .font(.subheadline)
          }
          .frame(maxWidth: .infinity)
          .frame(height: 50)
        }
      }
      .frame(maxWidth: .infinity)
    }
  }
}

/// A small heading over a group of the index list, eg. "Data views"
struct macosDropdownGroupHeading: View {
  var title: String

  var body: some View {
    Text(title)
      .font(.system(size: 11, weight: .semibold))
      .foregroundColor(Color("TextSecondary"))
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 10)
      .padding(.top, 8)
      .padding(.bottom, 4)
  }
}

/// A data view in the index list: its name with the pattern underneath
struct macosDropdownDataViewButton: View {
  var view: DataView
  var isSelected: Bool
  var action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: "rectangle.stack")
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(Color("LabelBackgroundFocus"))
        VStack(alignment: .leading, spacing: 1) {
          Text(view.name)
            .lineLimit(1)
          Text(view.pattern)
            .font(.system(size: 10.5, design: .monospaced))
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
            .truncationMode(.middle)
        }
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Color("LabelBackgroundFocus"))
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(height: 46)
      .padding(.horizontal, 5)
      .background(isHovered ? Color("BackgroundAlt").opacity(0.3) : Color.clear)
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
    .help("Search \(view.pattern)" + (view.timeField.isEmpty ? "" : " by \(view.timeField)"))
  }
}
