// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

// Settings → Request Logs: every request SearchOps recently made, with the selected one's details beside the list
struct macosRequestLogsView: View {
  @ObservedObject var logManager: LogDataManager
  @Binding var selectedID: UUID?
  let onBack: () -> Void

  @State private var isCleared = false

  private let listWidth: CGFloat = 380

  private var entries: [LogEvent] {
    logManager.newestFirst
  }

  private var selected: LogEvent? {
    entries.first { $0.id == selectedID }
  }

  private func clearLogs() {
    guard !isCleared else { return }
    selectedID = nil
    logManager.deleteAll()
    withAnimation(.easeInOut(duration: 0.3)) {
      isCleared = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.easeInOut(duration: 0.3)) {
        isCleared = false
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
        .padding(.top, 10)
        .padding(.bottom, 5)

      HStack(alignment: .top, spacing: 16) {
        list
          .frame(width: listWidth)
        detail
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(.horizontal, 10)
    .padding(.bottom, 10)
    .onAppear {
      logManager.refresh()
      if selected == nil {
        selectedID = entries.first?.id
      }
    }
  }

  private var header: some View {
    HStack(alignment: .bottom, spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Button(action: onBack) {
          Label("Settings", systemImage: "chevron.left")
        }
        .buttonStyle(macosSettingsButtonStyle())

        VStack(alignment: .leading, spacing: 4) {
          Text("Request Logs")
            .font(.system(size: 22, weight: .light))
            .foregroundColor(Color("TextColor"))
          Text("The last \(LogDataManager.limit) requests SearchOps made to your hosts, newest first.")
            .font(.system(size: 12))
        }
      }

      Spacer(minLength: 12)

      Button(action: clearLogs) {
        Label(isCleared ? "Cleared" : "Clear Logs",
              systemImage: isCleared ? "checkmark" : "trash")
      }
      .buttonStyle(macosSettingsButtonStyle(confirmed: isCleared))
      .opacity(entries.isEmpty && !isCleared ? 0.5 : 1)
      .disabled(entries.isEmpty)
    }
  }

  @ViewBuilder
  private var list: some View {
    if entries.isEmpty {
      Text("No requests recorded yet.")
        .font(.system(size: 12))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 5).fill(Color("Button")))
    } else {
      ScrollView {
        LazyVStack(spacing: 4) {
          ForEach(entries, id: \.id) { event in
            macosRequestLogRow(event: event, selected: event.id == selectedID) {
              selectedID = event.id
            }
          }
        }
        .padding(6)
      }
      .background(RoundedRectangle(cornerRadius: 5).fill(Color("Button")))
    }
  }

  @ViewBuilder
  private var detail: some View {
    if let event = selected {
      macosRequestLogDetailView(event: event)
        .id(event.id)
    } else {
      Text(entries.isEmpty
           ? "Searches, connection tests, index changes and Dev Console requests appear here."
           : "Select a request to see its details.")
        .font(.system(size: 12))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 5).fill(Color("Button")))
    }
  }
}

// One request in a list: method, path and status, then when, which host and what came back
struct macosRequestLogRow: View {
  let event: LogEvent
  var selected = false
  let action: () -> Void

  @State private var hovering = false

  private var fill: Color {
    if selected { return Color("ButtonHighlighted") }
    return Color(hovering ? "Background" : "BackgroundAlt")
  }

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(event.method.isEmpty ? "GET" : event.method)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
          Text(event.displayPath)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(selected ? .white : Color("TextColor"))
            .lineLimit(1)
            .truncationMode(.middle)
          Spacer(minLength: 6)
          macosRequestLogStatus(event: event)
        }

        HStack(spacing: 6) {
          Text(macosRequestLogFormat.time(event.date))
            .monospacedDigit()
          Text(event.host?.name ?? "")
            .lineLimit(1)
            .truncationMode(.tail)
          if let summary = event.resultSummary {
            Text("· " + summary)
              .lineLimit(1)
          }
          Spacer(minLength: 6)
          if !event.source.isEmpty {
            macosSettingsBadge(text: event.source)
          }
          Text(event.duration)
            .monospacedDigit()
            .lineLimit(1)
        }
        .font(.system(size: 11))
      }
      .foregroundColor(selected ? .white.opacity(0.85) : Color("TextSecondary"))
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(RoundedRectangle(cornerRadius: 5).fill(fill))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering = $0 }
    .animation(.easeInOut(duration: 0.15), value: hovering)
  }
}

// The HTTP status in its colour, or "Failed" when the request never got a response
struct macosRequestLogStatus: View {
  let event: LogEvent

  var body: some View {
    let failed = event.httpStatus == 0
    let color = failed ? Color.red : HTTPStatusColors.getStatusColor(input: event.httpStatus)
    Text(failed ? "Failed" : "\(event.httpStatus)")
      .font(.system(size: 11, weight: .semibold, design: .monospaced))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .foregroundColor(color)
      .background(RoundedRectangle(cornerRadius: 5).fill(color.opacity(0.18)))
  }
}

enum macosRequestLogFormat {
  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()

  private static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM HH:mm"
    return formatter
  }()

  private static let fullFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE d MMMM yyyy, HH:mm:ss"
    return formatter
  }()

  /// The time for today's requests, the day and time for older ones
  static func time(_ date: Date) -> String {
    Calendar.current.isDateInToday(date) ? timeFormatter.string(from: date) : dayFormatter.string(from: date)
  }

  static func full(_ date: Date) -> String {
    fullFormatter.string(from: date)
  }
}

#endif
