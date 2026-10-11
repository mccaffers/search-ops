// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
/// What the Save button offers, in the same style as a filter chip's actions. A search that came from a saved one
/// can update it or be saved as a new one; any other search goes straight to naming it.
struct macosSaveSearchPopover: View {
  /// The saved search being shown, nil for a search that isn't saved yet
  let linkedTitle: String?
  /// What differs from the saved search
  let changes: [SavedSearchState.Part]
  /// The name suggested for a search that isn't saved yet
  let suggestedName: String
  let onUpdate: () -> Void
  let onSaveNew: (String) -> Void
  let onClose: () -> Void

  private enum Step {
    case actions
    case name
  }

  @State private var step: Step = .actions
  @State private var name = ""
  @FocusState private var nameFocused: Bool

  var body: some View {
    Group {
      if step == .actions, let linkedTitle = linkedTitle {
        actions(linkedTitle)
      } else {
        nameStep
      }
    }
    .padding(6)
    .frame(width: 260, alignment: .leading)
    .background(Color("BackgroundAlt"))
    .onAppear {
      if linkedTitle == nil {
        showNameStep()
      }
    }
  }

  private func actions(_ title: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 13, weight: .medium))
          .lineLimit(1)
          .truncationMode(.middle)
        Text(SavedSearchState.changesLabel(changes))
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(2)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)

      Divider()
        .padding(.vertical, 2)

      macosPopoverActionRow(title: "Update \"\(title)\"", systemImage: "arrow.triangle.2.circlepath") {
        onUpdate()
      }
      .disabled(changes.isEmpty)
      .help(changes.isEmpty ? "Nothing has changed since it was saved" : "Replace the saved search with this one")
      .keyboardShortcut(.defaultAction)

      macosPopoverActionRow(title: "Save as New Search…", systemImage: "plus.square.on.square") {
        showNameStep()
      }
    }
  }

  private var nameStep: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(linkedTitle == nil ? "Save search" : "Save as new search")
        .font(.system(size: 13, weight: .medium))

      TextField("Name", text: $name)
        .textFieldStyle(PlainTextFieldStyle())
        .font(.system(size: 13))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color("Background"))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .focused($nameFocused)
        .onSubmit {
          onSaveNew(name)
        }
        // Escape goes back to the actions it came from, or closes when there are none
        .onExitCommand {
          if linkedTitle == nil {
            onClose()
          } else {
            step = .actions
          }
        }

      HStack {
        Spacer()
        Button("Cancel") {
          if linkedTitle == nil {
            onClose()
          } else {
            step = .actions
          }
        }
        .buttonStyle(macosDataViewButtonStyle())
        Button("Save") {
          onSaveNew(name)
        }
        .buttonStyle(macosDataViewButtonStyle(confirmed: true))
      }
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 4)
  }

  private func showNameStep() {
    name = linkedTitle.map(SavedSearch.copyTitle(of:)) ?? suggestedName
    step = .name
    // The field only takes focus once the popover is on screen
    DispatchQueue.main.async {
      nameFocused = true
    }
  }
}
#endif
