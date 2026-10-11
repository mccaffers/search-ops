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
/// can update it or be saved as a new one; any other search goes straight to naming it. A period that moves with
/// time, eg. "Last hour", can stay relative or be pinned to the dates it covers now.
struct macosSaveSearchPopover: View {
  /// The saved search being shown, nil for a search that isn't saved yet
  let linkedTitle: String?
  /// What differs from the saved search
  let changes: [SavedSearchState.Part]
  /// The name suggested for a search that isn't saved yet
  let suggestedName: String
  /// The search's time period, nil without a date field
  let period: DateRangeSnapshot?
  /// Whether the saved search pinned its period to fixed dates
  let linkedPinned: Bool
  /// Each passes whether to pin the period to fixed dates
  let onUpdate: (Bool) -> Void
  let onSaveNew: (String, Bool) -> Void
  let onClose: () -> Void

  private enum Step {
    case actions
    case name
  }

  @State private var step: Step = .actions
  @State private var name = ""
  @State private var pinPeriod = false
  @FocusState private var nameFocused: Bool

  /// Only a period that moves with time has a choice, fixed dates are fixed either way
  private var offersPeriodChoice: Bool {
    period?.isLive ?? false
  }

  /// What differs from the saved search, counting a switch between relative and fixed dates
  private var allChanges: [SavedSearchState.Part] {
    SavedSearchState.changes(changes,
                             pinningChanged: linkedTitle != nil && offersPeriodChoice && pinPeriod != linkedPinned)
  }

  private var savesPinned: Bool {
    offersPeriodChoice && pinPeriod
  }

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
      pinPeriod = linkedTitle != nil && linkedPinned
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
        Text(SavedSearchState.changesLabel(allChanges))
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(2)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)

      if offersPeriodChoice {
        periodChoice
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
      }

      Divider()
        .padding(.vertical, 2)

      macosPopoverActionRow(title: "Update \"\(title)\"", systemImage: "arrow.triangle.2.circlepath") {
        onUpdate(savesPinned)
      }
      .disabled(allChanges.isEmpty)
      .help(allChanges.isEmpty ? "Nothing has changed since it was saved" : "Replace the saved search with this one")
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
          onSaveNew(name, savesPinned)
        }
        // Escape goes back to the actions it came from, or closes when there are none
        .onExitCommand {
          if linkedTitle == nil {
            onClose()
          } else {
            step = .actions
          }
        }

      if offersPeriodChoice {
        periodChoice
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
          onSaveNew(name, savesPinned)
        }
        .buttonStyle(macosDataViewButtonStyle(confirmed: true))
      }
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 4)
  }

  /// Relative or fixed dates, and what each run of the saved search will cover
  private var periodChoice: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 2) {
        macosSettingsSegment(title: "Relative", selected: !pinPeriod) {
          pinPeriod = false
        }
        .help("Each run searches the period up to when it's run")
        macosSettingsSegment(title: "Fixed dates", selected: pinPeriod) {
          pinPeriod = true
        }
        .help("Each run searches the dates the period covers now")
      }
      .padding(2)
      .background(RoundedRectangle(cornerRadius: 5).fill(Color("Background")))

      Text(periodDescription)
        .font(.system(size: 11))
        .foregroundColor(Color("TextSecondary"))
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  /// eg. "Last hour, whenever it's run", or "Always 9 Oct 2026 at 14:00 – 9 Oct 2026 at 15:00"
  private var periodDescription: String {
    guard let period = period else { return "" }
    if pinPeriod, let fixed = SavedSearch.savedPeriod(period, pinned: true) {
      return "Always \(fixed.title)"
    }
    return "\(period.title), whenever it's run"
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
