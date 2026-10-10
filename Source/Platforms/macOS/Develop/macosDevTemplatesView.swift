// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)
/// Ready made requests for the API console, filled in from the selected index's mapping
struct macosDevTemplatesView: View {
  /// A copy of the selected host, the Realm object can be invalidated while requests are in flight
  var host: HostDetails
  var initialIndex: String
  var onUse: (String) -> Void
  var onClose: () -> Void

  @AppStorage("devConsole.templateIndex") private var lastIndex: String = ""

  @State private var index = ""
  @State private var loadedIndex = ""
  @State private var indices = [String]()
  @State private var fields = [TemplateField]()
  @State private var chosen = [TemplateFieldRole: TemplateField]()
  @State private var excluded = Set<TemplateFieldRole>()
  @State private var selected = DevConsoleTemplate.search
  @State private var range = TemplateTimeRange.default
  @State private var isLoading = false
  @State private var loadError: String? = nil
  @State private var loadTask: Task<Void, Never>? = nil

  /// The fields a template is rendered with, optional roles can be switched off
  private func fields(for template: DevConsoleTemplate) -> [TemplateFieldRole: TemplateField] {
    chosen.filter { role, _ in
      template.requiredRoles.contains(role) || !excluded.contains(role)
    }
  }

  private var preview: String? {
    guard !fields.isEmpty else { return nil }
    return selected.render(index: loadedIndex, fields: fields(for: selected), version: host.version, range: range)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      header

      HStack(alignment: .top, spacing: 10) {
        templateList
          .frame(width: 250)
        detail
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      footer
    }
    .padding(12)
    .background(Color("Background"))
    .clipShape(.rect(cornerRadius: 5))
    .shadow(color: Color.black.opacity(0.25), radius: 12, y: 4)
    .onAppear {
      let start = initialIndex.isEmpty ? lastIndex : initialIndex
      index = start
      if !start.isEmpty {
        loadFields()
      }
      Task {
        indices = await DevConsoleTemplateService.loadIndices(host: host)
        // Nothing to go on, start with the first index so the templates have fields
        if start.isEmpty && index.isEmpty, let first = indices.first {
          index = first
          loadFields()
        }
      }
    }
    .onDisappear {
      loadTask?.cancel()
    }
  }

  // MARK: Header

  private var header: some View {
    HStack(spacing: 8) {
      Text("Templates")
        .font(.system(size: 22, weight: .light))

      Spacer()

      HStack(spacing: 4) {
        Image(systemName: "tablecells")
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))

        TextField("Index or pattern, eg. logs-*", text: $index)
          .textFieldStyle(.plain)
          .font(.system(size: 12, design: .monospaced))
          .frame(width: 220)
          .onSubmit(loadFields)

        Menu {
          if indices.isEmpty {
            Text("No indices found")
          }
          ForEach(indices, id: \.self) { name in
            Button(name) {
              index = name
              loadFields()
            }
          }
        } label: {
          Image(systemName: "chevron.down")
            .font(.system(size: 10))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Choose an index")
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(Color("BackgroundAlt"))
      .clipShape(RoundedRectangle(cornerRadius: 5))

      Button(action: loadFields) {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 11))
          .padding(6)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .disabled(index.trimmingCharacters(in: .whitespaces).isEmpty)
      .help("Reload the mapping")

      HStack(spacing: 4) {
        Image(systemName: "server.rack")
          .font(.system(size: 11))
        Text(host.name)
          .font(.system(size: 12))
          .lineLimit(1)
      }
      .foregroundColor(Color("TextSecondary"))
      .padding(.horizontal, 4)

      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(.system(size: 11, weight: .semibold))
          .padding(6)
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .help("Close")
    }
  }

  // MARK: Templates

  private var templateList: some View {
    ScrollView {
      VStack(spacing: 6) {
        ForEach(DevConsoleTemplate.allCases) { template in
          templateCard(template)
        }
      }
    }
  }

  private func templateCard(_ template: DevConsoleTemplate) -> some View {
    let reason = fields.isEmpty ? nil : template.unavailableReason(fields: chosen)
    let isSelected = template == selected

    return Button(action: { selected = template }) {
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: template.systemImage)
          .font(.system(size: 14))
          .frame(width: 20)
          .padding(.top, 2)

        VStack(alignment: .leading, spacing: 3) {
          Text(template.title)
            .font(.system(size: 13, weight: .medium))
          Text(reason ?? template.summary(range: range))
            .font(.system(size: 11))
            .foregroundColor(Color(reason == nil ? "TextSecondary" : "WarnText"))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 0)
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color(isSelected ? "Button" : "BackgroundAlt"))
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .overlay(
        RoundedRectangle(cornerRadius: 5)
          .stroke(Color.accentColor.opacity(isSelected ? 0.8 : 0), lineWidth: 1)
      )
      .opacity(reason == nil ? 1 : 0.6)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
  }

  // MARK: Detail

  @ViewBuilder
  private var detail: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !fields.isEmpty && !selected.roles.isEmpty {
        HStack(spacing: 8) {
          ForEach(selected.roles, id: \.self) { role in
            fieldMenu(role)
          }
          if fields(for: selected)[.date] != nil {
            rangeMenu
          }
          Spacer()
        }
      }

      previewBody
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundAlt"))
        .clipShape(.rect(cornerRadius: 5))
    }
  }

  @ViewBuilder
  private func fieldMenu(_ role: TemplateFieldRole) -> some View {
    let candidates = TemplateFieldSuggester.candidates(for: role, in: fields)
    let isRequired = selected.requiredRoles.contains(role)
    let current = excluded.contains(role) && !isRequired ? nil : chosen[role]

    Menu {
      if !isRequired {
        Button(action: { excluded.insert(role) }) {
          if current == nil {
            Label("None", systemImage: "checkmark")
          } else {
            Text("None")
          }
        }
        Divider()
      }
      ForEach(candidates, id: \.self) { field in
        Button(action: {
          chosen[role] = field
          excluded.remove(role)
        }) {
          if field == current {
            Label("\(field.name)  (\(field.type))", systemImage: "checkmark")
          } else {
            Text("\(field.name)  (\(field.type))")
          }
        }
      }
    } label: {
      HStack(spacing: 4) {
        Text(role.title + ":")
          .foregroundColor(current == nil ? Color("TextSecondary") : Color.white.opacity(0.8))
        Text(current?.name ?? "None")
          .font(.system(size: 12, design: .monospaced))
          .lineLimit(1)
          .truncationMode(.middle)
      }
      .font(.system(size: 12))
    }
    .menuStyle(.borderlessButton)
    .fixedSize()
    .disabled(candidates.isEmpty)
    .padding(.horizontal, 8)
    .padding(.vertical, 5)
    .background(Color(current == nil ? "Button" : "macosGreenButton"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }

  /// Always has a value, so it's green like a chosen field
  private var rangeMenu: some View {
    Menu {
      ForEach(TemplateTimeRange.allCases) { option in
        Button(action: { range = option }) {
          if option == range {
            Label("Last \(option.title)", systemImage: "checkmark")
          } else {
            Text("Last \(option.title)")
          }
        }
      }
    } label: {
      HStack(spacing: 4) {
        Text("Time range:")
          .foregroundColor(Color.white.opacity(0.8))
        Text(range.dateMath)
          .font(.system(size: 12, design: .monospaced))
      }
      .font(.system(size: 12))
    }
    .menuStyle(.borderlessButton)
    .fixedSize()
    .padding(.horizontal, 8)
    .padding(.vertical, 5)
    .background(Color("macosGreenButton"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
  }

  @ViewBuilder
  private var previewBody: some View {
    if isLoading {
      ProgressView()
    } else if let loadError = loadError {
      stateMessage(icon: "exclamationmark.triangle", text: loadError, isWarning: true)
    } else if fields.isEmpty {
      stateMessage(icon: "tablecells", text: "Choose an index to build templates from its mapping")
    } else if let preview = preview {
      SelectableReadOnlyTextView(text: preview, showsScrollersWhenOverflowing: true)
    } else {
      stateMessage(icon: "exclamationmark.triangle",
                   text: selected.unavailableReason(fields: chosen) ?? "This template can't be used with this index",
                   isWarning: true)
    }
  }

  private func stateMessage(icon: String, text: String, isWarning: Bool = false) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 28))
        .foregroundColor(Color(isWarning ? "WarnText" : "TextSecondary"))
      Text(text)
        .font(.system(size: 13))
        .foregroundColor(Color("TextSecondary"))
        .multilineTextAlignment(.center)
        .textSelection(.enabled)
    }
    .padding()
  }

  // MARK: Footer

  private var footer: some View {
    HStack(spacing: 8) {
      if !fields.isEmpty && !isLoading {
        Text("\(fields.count) fields in \(loadedIndex)")
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
          .truncationMode(.middle)
      }

      Spacer()

      Button(action: onClose) {
        Text("Cancel")
          .font(.system(size: 12, weight: .medium))
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .keyboardShortcut(.cancelAction)

      Button(action: useTemplate) {
        HStack(spacing: 4) {
          Image(systemName: "square.and.arrow.down")
            .font(.system(size: 11))
          Text("Use template")
            .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color("macosGreenButton"))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .keyboardShortcut(.return, modifiers: .command)
      .disabled(preview == nil || isLoading)
      .help("Replace the request in the editor (⌘↩)")
    }
  }

  // MARK: Actions

  private func loadFields() {
    let requested = index.trimmingCharacters(in: .whitespaces)
    guard !requested.isEmpty else { return }

    loadTask?.cancel()
    isLoading = true
    loadError = nil

    loadTask = Task {
      let result = await DevConsoleTemplateService.loadFields(host: host, index: requested)
      // A newer index has been requested, its result will update the view
      guard !Task.isCancelled else { return }

      switch result {
      case .success(let loaded):
        fields = loaded
        chosen = TemplateFieldSuggester.suggestAll(in: loaded)
        excluded = []
        loadedIndex = requested
        lastIndex = requested
        // Keep the selection usable when the new mapping can't support it
        if selected.unavailableReason(fields: chosen) != nil,
           let usable = DevConsoleTemplate.allCases.first(where: { $0.unavailableReason(fields: chosen) == nil }) {
          selected = usable
        }
      case .failure(let error):
        fields = []
        chosen = [:]
        loadedIndex = ""
        loadError = error.localizedDescription
      }
      isLoading = false
      loadTask = nil
    }
  }

  private func useTemplate() {
    guard let preview = preview else { return }
    onUse(preview)
  }
}

#Preview {
  macosDevTemplatesView(host: HostDetails(),
                        initialIndex: "logs-*",
                        onUse: { _ in },
                        onClose: {})
    .frame(width: 900, height: 600)
}
#endif
