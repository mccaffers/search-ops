// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
/// One action in a popover list, eg. a filter chip's actions or saving a search: an icon and a title,
/// lit on hover, red when destructive and dimmed while disabled.
struct macosPopoverActionRow: View {
  let title: String
  let systemImage: String
  var isDestructive = false
  let action: () -> Void
  @Environment(\.isEnabled) private var isEnabled
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: systemImage)
          .frame(width: 16)
        Text(title)
          .lineLimit(1)
          .truncationMode(.middle)
        Spacer(minLength: 0)
      }
      .font(.system(size: 13))
      .foregroundColor(isDestructive ? Color("RedIcon") : Color("TextColor"))
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(isHovered && isEnabled ? Color("Button") : Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .contentShape(Rectangle())
      .opacity(isEnabled ? 1 : 0.45)
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
  }
}
#endif
