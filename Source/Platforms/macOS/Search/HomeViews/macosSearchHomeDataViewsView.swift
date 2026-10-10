// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
/// The host's data views on the search home screen, between the hosts and the indices.
/// Choosing one searches its pattern with its time field; choosing it again clears it.
struct macosSearchHomeDataViewsView: View {
  var dataViews: [DataView]
  var selectedDataView: DataView?
  var onSelect: (DataView) -> Void
  var onClear: () -> Void
  var onNew: () -> Void

  @State private var isNewHovered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text("Data views")
        .font(.subheadline)
        .foregroundStyle(Color("TextSecondary"))

      WrappingHStack(horizontalSpacing: 5) {
        ForEach(dataViews) { view in
          macosSearchHomeDataViewChip(view: view, isSelected: view.id == selectedDataView?.id) {
            if view.id == selectedDataView?.id {
              onClear()
            } else {
              onSelect(view)
            }
          }
        }

        Button(action: onNew) {
          Image(systemName: "plus")
            .font(.system(size: 18, weight: .medium))
            .frame(width: macosSearchHomeDataViewChip.height, height: macosSearchHomeDataViewChip.height)
            .background(isNewHovered ? Color("ButtonHighlighted") : Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isNewHovered = hovering
        }
        .help("New data view (opens Manage)")
        .accessibilityLabel("New data view")
      }
    }
    .padding(.bottom, 5)
  }
}

struct macosSearchHomeDataViewChip: View {
  /// Shared with the plus button beside the chips, so they line up
  static let height: CGFloat = 44

  var view: DataView
  var isSelected: Bool
  var action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Image(systemName: "rectangle.stack")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color("LabelBackgroundFocus"))
          Text(view.name)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
        }
        Text(view.pattern)
          .font(.system(size: 10.5, design: .monospaced))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
          .truncationMode(.middle)
      }
      .padding(.horizontal, 10)
      .frame(height: Self.height)
      .background(isSelected || isHovered ? Color("ButtonHighlighted") : Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
      .overlay(
        RoundedRectangle(cornerRadius: 5)
          .stroke(Color("LabelBackgroundFocus"), lineWidth: isSelected ? 1 : 0)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
    .help(isSelected ? "Stop using \(view.name)" : "Search \(view.pattern)" + (view.timeField.isEmpty ? "" : " by \(view.timeField)"))
  }
}
#endif
