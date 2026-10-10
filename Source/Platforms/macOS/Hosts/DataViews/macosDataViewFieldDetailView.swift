// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
/// A panel over the data view editor for one field: its path and type, a few recent values,
/// and its label. Saving puts the label in the editor's draft; the editor's Save stores it.
struct macosDataViewFieldDetailView: View {
  var host: HostDetails
  var pattern: String
  var timeField: String
  var field: SquashedFieldsArray
  var label: String
  var onSave: (String) -> Void
  var onClose: () -> Void

  @State private var text: String = ""
  @State private var values: [String] = []
  @State private var valuesError: String? = nil
  @State private var isLoadingValues: Bool = true
  @State private var offset: CGFloat = 600
  @State private var isCloseHovered: Bool = false
  @FocusState private var labelFocused: Bool

  private var trimmedText: String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var types: [String] {
    field.type.components(separatedBy: ", ").filter { !$0.isEmpty }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center) {
        Text("Field")
          .font(.system(size: 18))
          .padding(.leading, 15)

        Spacer()

        Button(action: onClose) {
          Image(systemName: "xmark")
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 28, height: 28)
            .background(isCloseHovered ? Color("ButtonHighlighted") : Color("Background"))
            .clipShape(.rect(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
          isCloseHovered = hovering
        }
        .help("Close")
        .padding(.trailing, 10)
      }
      .padding(.vertical, 8)
      .background(Color("Button"))

      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          fieldSection
          labelSection
          valuesSection
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("BackgroundAlt"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .frame(maxWidth: 520)
    .padding(.vertical, 10)
    .padding(.trailing, 10)
    .offset(x: offset)
    .animation(.spring(response: 0.25, dampingFraction: 1, blendDuration: 0), value: offset)
    .onAppear {
      text = label
      offset = 0
      labelFocused = true
    }
    .task {
      await loadValues()
    }
  }

  // MARK: - Sections

  private var fieldSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(field.squashedString)
        .font(.system(size: 15, weight: .medium, design: .monospaced))
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 6) {
        ForEach(types, id: \.self) { type in
          macosFieldTypeBadgeView(type: type)
        }
        if types.count > 1 {
          Text("The indexes in this pattern map it differently")
            .font(.caption)
            .foregroundColor(.orange)
        }
      }

      if field.fieldParts.count > 1 {
        Text(field.fieldParts.joined(separator: " › "))
          .font(.system(size: 11, design: .monospaced))
          .foregroundColor(Color("TextSecondary"))
          .help("Where the field sits in the document")
      }
    }
  }

  private var labelSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionTitle("Label")

      TextField("eg. MAE p50 (points)", text: $text)
        .textFieldStyle(PlainTextFieldStyle())
        .font(.system(size: 13))
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color("Background"))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .focused($labelFocused)
        .onSubmit(save)
        .onExitCommand(perform: onClose)

      Text("Shown instead of the field name in this data view.")
        .font(.caption)
        .foregroundColor(Color("TextSecondary"))

      HStack(spacing: 8) {
        if !label.isEmpty {
          Button("Remove label") {
            onSave("")
          }
          .buttonStyle(macosDataViewButtonStyle())
        }
        Spacer()
        Button("Cancel", action: onClose)
          .buttonStyle(macosDataViewButtonStyle())
        Button("Save label", action: save)
          .buttonStyle(macosDataViewButtonStyle())
          .disabled(trimmedText == label || (trimmedText.isEmpty && label.isEmpty))
      }
    }
  }

  private var valuesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        sectionTitle("Recent values")
        if !timeField.isEmpty {
          Text("newest by \(timeField)")
            .font(.caption)
            .foregroundColor(Color("TextSecondary"))
        }
      }

      if isLoadingValues {
        ProgressView()
          .controlSize(.small)
      } else if let valuesError = valuesError {
        Text(valuesError)
          .font(.caption)
          .foregroundColor(.orange)
          .textSelection(.enabled)
      } else if values.isEmpty {
        Text("No documents have a value for this field yet.")
          .font(.caption)
          .foregroundColor(Color("TextSecondary"))
      } else {
        ForEach(values, id: \.self) { value in
          Text(value)
            .font(.system(size: 12, design: .monospaced))
            .textSelection(.enabled)
            .lineLimit(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color("Button"))
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
      }
    }
  }

  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .font(.system(size: 13, weight: .semibold))
  }

  // MARK: - Actions

  private func save() {
    guard trimmedText != label else {
      onClose()
      return
    }
    onSave(trimmedText)
  }

  private func loadValues() async {
    guard !host.isInvalidated else {
      isLoadingValues = false
      return
    }
    let result = await DataViewFieldSamples.fetch(serverDetails: host.generateCopy(),
                                                  pattern: pattern,
                                                  field: field.squashedString,
                                                  timeField: timeField)
    guard !Task.isCancelled else { return }
    values = result.values
    valuesError = result.error?.message
    isLoadingValues = false
  }
}
#endif
