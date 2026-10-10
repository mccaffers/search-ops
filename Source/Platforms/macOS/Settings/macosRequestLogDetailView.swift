// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

// The details of one logged request: where it went, what was sent and what came back
struct macosRequestLogDetailView: View {
  // Read once, the event can be deleted (eg. Clear Logs) while this view is still on screen
  private let method: String
  private let path: String
  private let date: Date
  private let source: String
  private let status: Int
  private let duration: String
  private let resultSummary: String?
  private let hostName: String
  private let environment: String
  private let index: String
  private let dateField: String
  private let scheme: String
  private let address: String
  private let errorTitle: String?
  private let errorMessage: String?
  private let requestBody: String
  private let requestTruncated: Bool
  private let responseBody: String
  private let responseTruncated: Bool

  init(event: LogEvent) {
    method = event.method.isEmpty ? "GET" : event.method
    path = event.displayPath
    date = event.date
    source = event.source
    status = event.httpStatus
    duration = event.duration
    resultSummary = event.resultSummary
    hostName = event.host?.name ?? ""
    environment = event.host?.env ?? ""
    index = event.index
    dateField = event.filter?.dateField?.squashedString ?? ""
    scheme = event.host?.host?.scheme.rawValue ?? ""
    address = event.host?.host?.url ?? ""
    errorTitle = event.error?.title
    errorMessage = event.error?.message
    requestBody = event.jsonReq
    requestTruncated = event.jsonReqTruncated
    responseBody = event.jsonRes
    responseTruncated = event.jsonResTruncated
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        summaryCard

        ViewThatFits(in: .horizontal) {
          HStack(alignment: .top, spacing: 16) {
            hostCard
            requestCard
          }
          VStack(spacing: 16) {
            hostCard
            requestCard
          }
        }

        macosRequestLogBodyCard(title: "Request Body", text: requestBody, truncated: requestTruncated)
        macosRequestLogBodyCard(title: "Response Body", text: responseBody, truncated: responseTruncated)
      }
    }
  }

  private var summaryCard: some View {
    macosSettingsCard(title: method + " " + path,
                      subtitle: macosRequestLogFormat.full(date),
                      badge: source.isEmpty ? nil : macosSettingsBadge(text: source)) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 12) {
          statusLabel
          if !duration.isEmpty {
            Text(duration)
              .font(.system(size: 12).monospacedDigit())
          }
          if let resultSummary = resultSummary {
            Text(resultSummary)
              .font(.system(size: 12))
          }
          Spacer(minLength: 0)
        }

        if let errorTitle = errorTitle, let errorMessage = errorMessage {
          VStack(alignment: .leading, spacing: 3) {
            Text(errorTitle)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(Color("TextColor"))
            Text(errorMessage)
              .font(.system(size: 11))
              .fixedSize(horizontal: false, vertical: true)
              .textSelection(.enabled)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(12)
          .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
        }
      }
    }
  }

  private var statusLabel: some View {
    let failed = status == 0
    let color = failed ? Color.red : HTTPStatusColors.getStatusColor(input: status)
    return Text(failed ? "Failed" : "HTTP \(status)")
      .font(.system(size: 11, weight: .semibold, design: .monospaced))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .foregroundColor(color)
      .background(RoundedRectangle(cornerRadius: 5).fill(color.opacity(0.18)))
  }

  private var hostCard: some View {
    macosSettingsCard(title: "Host") {
      keyValueSection([
        ("Name", hostName),
        ("Environment", environment),
        ("Index", index),
        ("Date Field", dateField)
      ])
    }
  }

  private var requestCard: some View {
    macosSettingsCard(title: "HTTP Request") {
      keyValueSection([
        ("Method", method),
        ("Scheme", scheme),
        ("Host", address),
        ("Path", path)
      ])
    }
  }

  // Rows with no value are left out, eg. there's no index for a connection test
  private func keyValueSection(_ rows: [(String, String)]) -> some View {
    let shown = rows.filter { !$0.1.isEmpty }
    return VStack(spacing: 0) {
      ForEach(Array(shown.enumerated()), id: \.offset) { position, row in
        if position > 0 {
          macosSettingsDivider(color: Color("Button"))
        }
        macosKeyValueRow(label: row.0, value: row.1)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
    .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
  }
}

// A request or response body, pretty printed away from the main thread, with a copy button
struct macosRequestLogBodyCard: View {
  let title: String
  let text: String
  let truncated: Bool

  @State private var formatted: String? = nil
  @State private var copied = false

  private var subtitle: String {
    let size = ByteCountFormatter.string(fromByteCount: Int64(text.utf8.count), countStyle: .file)
    if truncated {
      return "\(size), only the first \(ByteCountFormatter.string(fromByteCount: Int64(LogEvent.bodyLimit), countStyle: .file)) was kept."
    }
    return size
  }

  // Tall enough for short bodies, longer ones scroll inside the box
  private var height: CGFloat {
    let lines = (formatted ?? text).reduce(into: 1) { count, character in
      if character == "\n" { count += 1 }
    }
    return CGFloat(min(max(lines, 3), 24)) * 15 + 20
  }

  private func copy() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(formatted ?? text, forType: .string)
    withAnimation(.easeInOut(duration: 0.2)) {
      copied = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.easeInOut(duration: 0.2)) {
        copied = false
      }
    }
  }

  var body: some View {
    macosSettingsCard(title: title, subtitle: text.isEmpty ? nil : subtitle) {
      if text.isEmpty {
        Text("No body")
          .font(.system(size: 12))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(12)
          .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
      } else {
        VStack(alignment: .trailing, spacing: 8) {
          Group {
            if let formatted = formatted {
              SelectableReadOnlyTextView(text: formatted, showsScrollersWhenOverflowing: true)
            } else {
              ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
          }
          .frame(height: height)
          .frame(maxWidth: .infinity)
          .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
          .clipShape(RoundedRectangle(cornerRadius: 5))

          Button(action: copy) {
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
          }
          .buttonStyle(macosSettingsButtonStyle(confirmed: copied))
        }
        .task {
          let raw = text
          formatted = await Task.detached(priority: .userInitiated) {
            DevConsoleService.formatBody(Data(raw.utf8)).text
          }.value
        }
      }
    }
  }
}

#endif
