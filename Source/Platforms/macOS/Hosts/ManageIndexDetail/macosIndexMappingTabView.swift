// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(macOS)
import AppKit

public enum MappingDisplayMode: String, CaseIterable {
  case structured = "Structured Fields"
  case rawJson = "Raw JSON"
}

public struct macosFieldTypeBadgeView: View {
  public var type: String

  public init(type: String) {
    self.type = type
  }

  private var badgeColor: Color {
    let lower = type.lowercased()
    switch lower {
    case "date", "date_nanos":
      return Color.blue
    case "keyword":
      return Color.green
    case "text":
      return Color.orange
    case "long", "integer", "short", "byte", "double", "float", "half_float", "scaled_float":
      return Color.purple
    case "boolean":
      return Color.pink
    case "ip", "geo_point", "geo_shape":
      return Color.indigo
    case "nested", "object":
      return Color.gray
    default:
      return Color("TextSecondary")
    }
  }

  public var body: some View {
    Text(type.isEmpty ? "unknown" : type)
      .font(.system(size: 10, weight: .medium, design: .monospaced))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(badgeColor.opacity(0.18))
      .foregroundColor(badgeColor)
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(badgeColor.opacity(0.35), lineWidth: 0.8)
      )
  }
}

public struct SelectableReadOnlyTextView: NSViewRepresentable {
  public var text: String

  public init(text: String) {
    self.text = text
  }

  public func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.drawsBackground = false

    let textView = NSTextView()
    textView.isEditable = false
    textView.isSelectable = true
    textView.drawsBackground = false
    textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    textView.textColor = NSColor.textColor
    textView.typingAttributes = [
      .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
      .foregroundColor: NSColor.textColor
    ]
    textView.string = text
    textView.textContainerInset = NSSize(width: 8, height: 8)
    textView.isHorizontallyResizable = true
    textView.isVerticallyResizable = true
    textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.textContainer?.widthTracksTextView = false
    textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

    scrollView.documentView = textView
    return scrollView
  }

  public func updateNSView(_ nsView: NSScrollView, context: Context) {
    if let textView = nsView.documentView as? NSTextView {
      if textView.string != text {
        textView.string = text
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = NSColor.textColor
      }
    }
  }
}

struct macosMappingFieldRowView: View {
  var field: SquashedFieldsArray
  @State private var isHovered = false

  private var isDateField: Bool {
    field.type == "date" || field.type == "date_nanos"
  }

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: isDateField ? "calendar.badge.clock" : "tag")
        .font(.system(size: 11))
        .foregroundColor(isDateField ? .blue : Color("TextSecondary"))
        .frame(width: 14)

      Text(field.squashedString)
        .font(.system(size: 12, weight: .regular, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)

      Spacer()

      if isDateField {
        HStack(spacing: 3) {
          Image(systemName: "clock")
            .font(.system(size: 9))
          Text("date")
            .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 1.5)
        .background(Color.blue.opacity(0.15))
        .foregroundColor(.blue)
        .clipShape(Capsule())
      }

      macosFieldTypeBadgeView(type: field.type)
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 10)
    .background(isHovered ? Color("ButtonHighlighted") : Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .contentShape(Rectangle())
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

public struct macosIndexMappingTabView: View {
  public var fields: [SquashedFieldsArray]
  public var rawJson: String

  @State private var searchText: String = ""
  @State private var displayMode: MappingDisplayMode = .structured
  @State private var isCopied: Bool = false
  @State private var copyTask: Task<Void, Never>? = nil

  public init(fields: [SquashedFieldsArray], rawJson: String) {
    self.fields = fields
    self.rawJson = rawJson
  }

  private var prettifiedJson: String {
    rawJson.prettifyJSON()
  }

  private var filteredFields: [SquashedFieldsArray] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return fields
    }
    return fields.filter {
      $0.squashedString.localizedCaseInsensitiveContains(trimmed) ||
      $0.type.localizedCaseInsensitiveContains(trimmed)
    }
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Controls Bar
      HStack(spacing: 10) {
        if displayMode == .structured {
          HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(Color("TextSecondary"))
              .font(.system(size: 12))
            TextField("Filter fields...", text: $searchText)
              .textFieldStyle(PlainTextFieldStyle())
              .font(.system(size: 12))
            if !searchText.isEmpty {
              Button(action: { searchText = "" }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(Color("TextSecondary"))
                  .font(.system(size: 11))
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 5)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
        }

        Spacer()

        SwiftUI.Picker("", selection: $displayMode) {
          ForEach(MappingDisplayMode.allCases, id: \.self) { mode in
            Text(mode.rawValue).tag(mode)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 240)

        if displayMode == .structured {
          Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(fields.count) fields" : "\(filteredFields.count) / \(fields.count) fields")
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("Button"))
            .clipShape(Capsule())
            .foregroundColor(Color("TextSecondary"))
        } else {
          Button(action: copyJsonToClipboard) {
            HStack(spacing: 4) {
              Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 11))
              Text(isCopied ? "Copied!" : "Copy JSON")
                .font(.system(size: 11))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("Button"))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .disabled(prettifiedJson.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }

      // Main Content Area
      if displayMode == .structured {
        if filteredFields.isEmpty {
          VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
              .font(.system(size: 28))
              .foregroundColor(Color("TextSecondary"))
            Text(fields.isEmpty ? "No fields in mapping" : "No matching fields")
              .font(.headline)
            if !fields.isEmpty {
              Text("Try refining your search filter.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.top, 40)
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
              ForEach(filteredFields, id: \.id) { field in
                macosMappingFieldRowView(field: field)
              }
            }
          }
        }
      } else {
        if prettifiedJson.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          VStack(spacing: 8) {
            Image(systemName: "doc.text")
              .font(.system(size: 28))
              .foregroundColor(Color("TextSecondary"))
            Text("No mapping JSON available")
              .font(.headline)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.top, 40)
        } else {
          SelectableReadOnlyTextView(text: prettifiedJson)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Button").opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
      }
    }
  }

  private func copyJsonToClipboard() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(prettifiedJson, forType: .string)
    isCopied = true

    copyTask?.cancel()
    copyTask = Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      if !Task.isCancelled {
        await MainActor.run {
          isCopied = false
        }
      }
    }
  }
}
#endif
