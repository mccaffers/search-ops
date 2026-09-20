// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
struct macosManageHostOptionsView: View {
  var host: HostDetails
  var onBack: () -> Void
  var onListIndexes: () -> Void

  @State private var isListIndexesHovered: Bool = false
  @State private var isBackHovered: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Top-left header with back button and host details
      HStack(spacing: 8) {
        Button(action: onBack) {
          Image(systemName: "chevron.left")
            .font(.system(size: 14, weight: .semibold))
            .padding(6)
            .background(isBackHovered ? Color("ButtonHighlighted") : Color.clear)
            .clipShape(.rect(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isBackHovered = hovering
        }
        .help("Back to hosts")

        VStack(alignment: .leading, spacing: 2) {
          Text(!host.isInvalidated ? host.name : "Host")
            .font(.system(size: 20, weight: .light))
            .lineLimit(1)
          if !host.isInvalidated && !host.env.isEmpty {
            Text(host.env)
              .font(.subheadline)
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
          }
        }

        Spacer()
      }
      .padding(.top, 10)
      .padding(.bottom, 5)

      // Options List
      VStack(alignment: .leading, spacing: 8) {
        Button(action: onListIndexes) {
          HStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
              .font(.system(size: 16))
              .foregroundColor(Color.accentColor)
              .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
              Text("List indexes")
                .font(.system(size: 14, weight: .medium))
              Text("View all indices available on this cluster")
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
            }

            Spacer()

            Image(systemName: "chevron.right")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(Color("TextSecondary"))
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(isListIndexesHovered ? Color("ButtonHighlighted") : Color("Button"))
          .clipShape(.rect(cornerRadius: 5))
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isListIndexesHovered = hovering
        }
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  let host = HostDetails()
  host.name = "Production Cluster"
  host.env = "Production"
  return macosManageHostOptionsView(host: host, onBack: {}, onListIndexes: {})
    .frame(width: 400, height: 500)
    .padding()
}
#endif
