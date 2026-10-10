// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
struct macosManageDataViewsView: View {
  var host: HostDetails
  var onBack: () -> Void
  var onCreate: () -> Void
  var onEdit: (UUID) -> Void

  @State private var views: [DataView] = []
  @State private var pendingDelete: DataView? = nil
  @State private var isBackHovered: Bool = false

  private let manager = DataViewDataManager()

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Top-left header with back button and view count
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
        .help("Back to host options")

        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text("Data views")
              .font(.system(size: 20, weight: .light))
            if !views.isEmpty {
              Text("\(views.count)")
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color("Button"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .foregroundColor(Color("TextSecondary"))
            }
          }
          if !host.isInvalidated {
            Text(host.name)
              .font(.subheadline)
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
          }
        }

        Spacer()

        if !views.isEmpty {
          newButton
        }
      }
      .padding(.top, 10)
      .padding(.bottom, 2)

      if views.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "rectangle.stack")
            .font(.system(size: 28))
            .foregroundColor(Color("TextSecondary"))
          Text("No data views yet")
            .font(.headline)
          Text("A data view saves an index pattern, such as logs-*, with a default time field and labels for its fields.")
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 360)
          newButton
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(views) { view in
              macosDataViewRowView(
                view: view,
                onEdit: { onEdit(view.id) },
                onDelete: { pendingDelete = view }
              )
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      reload()
    }
    .alert(
      "Delete Data View?",
      isPresented: Binding(
        get: { pendingDelete != nil },
        set: { if !$0 { pendingDelete = nil } }
      ),
      presenting: pendingDelete
    ) { view in
      Button("Cancel", role: .cancel) { }
      Button("Delete", role: .destructive) {
        manager.delete(id: view.id)
        reload()
      }
    } message: { view in
      Text(Self.deleteMessage(for: view))
    }
  }

  private var newButton: some View {
    Button(action: onCreate) {
      HStack(spacing: 4) {
        Image(systemName: "plus")
        Text("New data view")
      }
    }
    .buttonStyle(macosDataViewButtonStyle())
  }

  static func deleteMessage(for view: DataView) -> String {
    let labels: String
    switch view.labels.count {
    case 0: labels = ""
    case 1: labels = " Its field label will be removed."
    default: labels = " Its \(view.labels.count) field labels will be removed."
    }
    return "\"\(view.name)\" will be removed from this Mac.\(labels) Indexes on the cluster aren't affected."
  }

  private func reload() {
    guard !host.isInvalidated else {
      views = []
      return
    }
    views = manager.views(hostId: host.id)
  }
}

struct macosDataViewRowView: View {
  var view: DataView
  var onEdit: () -> Void
  var onDelete: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: onEdit) {
      HStack(spacing: 10) {
        Image(systemName: "rectangle.stack")
          .font(.system(size: 14))
          .foregroundColor(Color.accentColor)
          .frame(width: 20)

        VStack(alignment: .leading, spacing: 3) {
          Text(view.name)
            .font(.system(size: 14, weight: .medium))
            .lineLimit(1)
          Text(view.pattern)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
            .truncationMode(.middle)
        }

        Spacer()

        if !view.timeField.isEmpty {
          chip(icon: "clock", text: view.timeField)
        }
        if !view.labels.isEmpty {
          chip(icon: "tag", text: view.labels.count == 1 ? "1 label" : "\(view.labels.count) labels")
        }

        Menu {
          Button("Edit", action: onEdit)
          Divider()
          Button("Delete…", role: .destructive, action: onDelete)
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color("TextSecondary"))
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More actions")

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(Color("TextSecondary"))
      }
      .padding(.vertical, 8)
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
    .contextMenu {
      Button("Edit", action: onEdit)
      Divider()
      Button("Delete…", role: .destructive, action: onDelete)
    }
  }

  private func chip(icon: String, text: String) -> some View {
    HStack(spacing: 3) {
      Image(systemName: icon)
        .font(.system(size: 9))
      Text(text)
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .lineLimit(1)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(Color("BackgroundFixedShadow"))
    .foregroundColor(Color("TextSecondary"))
    .clipShape(Capsule())
  }
}

#Preview {
  let host = HostDetails()
  host.name = "Production Cluster"
  return macosManageDataViewsView(host: host, onBack: {}, onCreate: {}, onEdit: { _ in })
    .frame(width: 600, height: 400)
    .padding()
}
#endif
