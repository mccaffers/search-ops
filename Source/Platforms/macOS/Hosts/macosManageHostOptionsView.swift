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
  var onClusterHealth: () -> Void
  var onListIndexes: () -> Void
  var onListUsers: () -> Void
  var onDataViews: () -> Void

  @State private var isBackHovered: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Top-left header with back button and host details
      HStack(spacing: 8) {
        Button(action: onBack) {
          Image(systemName: "chevron.left")
            .font(.system(size: 20, weight: .semibold))
            .padding(8)
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
        macosManageHostOptionRow(
          icon: "waveform.path.ecg",
          title: "Cluster health",
          subtitle: "Status, shards, nodes and resource usage",
          action: onClusterHealth
        )
        macosManageHostOptionRow(
          icon: "list.bullet.rectangle",
          title: "List indexes",
          subtitle: "View all indices available on this cluster",
          action: onListIndexes
        )
        macosManageHostOptionRow(
          icon: "person.2",
          title: "List users",
          subtitle: "View all users configured on this cluster",
          action: onListUsers
        )
        macosManageHostOptionRow(
          icon: "rectangle.stack",
          title: "Data views",
          subtitle: "Saved index patterns with field labels",
          action: onDataViews
        )
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct macosManageHostOptionRow: View {
  var icon: String
  var title: String
  var subtitle: String
  var action: () -> Void

  @State private var isHovered: Bool = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 16))
          .foregroundColor(Color.accentColor)
          .frame(width: 24)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.system(size: 14, weight: .medium))
          Text(subtitle)
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
      .background(isHovered ? Color("ButtonHighlighted") : Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

#Preview {
  let host = HostDetails()
  host.name = "Production Cluster"
  host.env = "Production"
  return macosManageHostOptionsView(host: host, onBack: {}, onClusterHealth: {}, onListIndexes: {}, onListUsers: {}, onDataViews: {})
    .frame(width: 400, height: 500)
    .padding()
}
#endif
