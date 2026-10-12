// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)
struct macosHostsListView: View {

  var hosts : [HostDetails]
  var selection: macosSearchViewEnum
  var onAdd : () -> Void
  var onSelect : (HostDetails) -> Void

  @State private var isAddHovered = false

    var body: some View {
      VStack {
        HStack(spacing:2) {

          Text("Host Management")
            .font(.system(size: 22, weight:.light))


          Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 0)
        .opacity(selection != .None ? 0.4 : 1)

        VStack(alignment:.leading, spacing:5){

          Button(action: onAdd) {
            HStack(spacing:5) {
              Image(systemName: "plus.app.fill")
              Text("Add a new host")
            }
            .padding(10)
            .background(isAddHovered ? Color("ButtonHighlighted") : Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .onHover { hovering in
            isAddHovered = hovering
          }
          .padding(.bottom, 5)
          .opacity(selection != .None ? 0.4 : 1)

          if hosts.isEmpty {
            RepeatedPlaceholderView()
            Spacer()
          } else {
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(hosts, id: \.id) { item in
                  macosManageHostCardView(item: item) {
                    onSelect(item)
                  }
                }
              }
            }
            .opacity(selection != .None ? 0.4 : 1)
          }

        }
        .frame(maxWidth: .infinity,alignment: .leading)

      }
    }
}
#endif

struct RepeatedPlaceholderView: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<5) { _ in
                VStack(alignment: .leading) {
                    Text("Name")
                    Text("Environment")
                        .font(.subheadline)
                }
                .padding(.vertical, 10)
                .padding(.leading, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("Button"))
                .redacted(reason: .placeholder)
                .opacity(0.5)
            }
        }
    }
}
