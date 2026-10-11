// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

struct SettingsView: View {
  @ObservedObject var searchHistoryManager: SearchHistoryDataManager
  @Binding var fullScreen: Bool

  @State private var isCleared = false
  @AppStorage(IndexManagementPreferences.readOnlyKey) private var indexReadOnly: Bool = IndexManagementPreferences.readOnlyDefault
  @StateObject private var settingsManager = SettingsDataManager()
  @State private var documentsPerPageText = ""
  @State private var documentsPerPageSaved = false
  @State private var documentsPerPageSavedFlash = 0
  @FocusState private var documentsPerPageFocused: Bool
  @State private var commitCopied = false
  @State private var databaseSize: Double = 0
  @StateObject private var logManager = LogDataManager()
  @State private var showingLogs = false
  @State private var selectedLogID: UUID? = nil
  @State private var logsCleared = false

  private let sideColumnWidth: CGFloat = 340

  private var documentsPerPageInput: Int? {
    SettingsDataManager.parseDocumentsPerPage(documentsPerPageText)
  }

  private var canSaveDocumentsPerPage: Bool {
    guard let value = documentsPerPageInput else { return false }
    return value != settingsManager.documentsPerPage
  }

  // Writes the value and reports whether it stuck, eg. the database may be unavailable
  private func storeDocumentsPerPage(_ value: Int) -> Bool {
    settingsManager.setDocumentsPerPage(input: value)
    guard settingsManager.documentsPerPage == value else { return false }
    documentsPerPageText = String(value)
    return true
  }

  private func saveDocumentsPerPage() {
    guard canSaveDocumentsPerPage, let value = documentsPerPageInput,
          storeDocumentsPerPage(value) else { return }
    flashDocumentsPerPageSaved()
  }

  // Shows "Saved" in green, then the button goes back to inactive. A newer flash keeps it green for its full time
  private func flashDocumentsPerPageSaved() {
    documentsPerPageSavedFlash += 1
    let flash = documentsPerPageSavedFlash
    withAnimation(.easeInOut(duration: 0.3)) {
      documentsPerPageSaved = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      guard flash == documentsPerPageSavedFlash else { return }
      withAnimation(.easeInOut(duration: 0.3)) {
        documentsPerPageSaved = false
      }
    }
  }

  private func clearRecentSearches() {
    guard !isCleared else { return }
    searchHistoryManager.deleteAll()
    withAnimation(.easeInOut(duration: 0.3)) {
      isCleared = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.easeInOut(duration: 0.3)) {
        isCleared = false
      }
    }
  }

  private func clearLogs() {
    guard !logsCleared else { return }
    logManager.deleteAll()
    withAnimation(.easeInOut(duration: 0.3)) {
      logsCleared = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.easeInOut(duration: 0.3)) {
        logsCleared = false
      }
    }
  }

  // Opens Request Logs with `id` selected, or the newest request when nil
  private func openLogs(selecting id: UUID? = nil) {
    selectedLogID = id ?? logManager.newestFirst.first?.id
    showingLogs = true
  }

  private func copyCommit(_ commit: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(commit, forType: .string)
    withAnimation(.easeInOut(duration: 0.2)) {
      commitCopied = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.easeInOut(duration: 0.2)) {
        commitCopied = false
      }
    }
  }

  var body: some View {
    Group {
      if showingLogs {
        macosRequestLogsView(logManager: logManager,
                             selectedID: $selectedLogID,
                             onBack: { showingLogs = false })
      } else {
        settingsPage
      }
    }
    .foregroundColor(Color("TextSecondary"))
    .background(Color("BackgroundFixedShadow"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .padding(.leading, 3)
    .padding(.trailing, 5)
    .padding(.bottom, 5)
    .padding(.top, fullScreen ? 5 : 0)
  }

  private var settingsPage: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Settings")
            .font(.system(size: 22, weight: .light))
            .foregroundColor(Color("TextColor"))
          Text("Search preferences, index safety, build details and ways to get in touch.")
            .font(.system(size: 12))
        }
        .padding(.top, 10)
        .padding(.bottom, 5)

        // Two columns when there's room, otherwise the side cards follow the main ones
        macosSettingsColumns(mainIdealWidth: 440, sideWidth: sideColumnWidth, spacing: 16) {
          VStack(spacing: 16) { mainCards }
            .frame(maxWidth: .infinity)
          VStack(spacing: 16) { sideCards }
            .frame(maxWidth: .infinity)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 10)
      .padding(.bottom, 10)
    }
    .onAppear {
      documentsPerPageText = String(settingsManager.documentsPerPage)
      databaseSize = RealmManager.checkRealmFileSize()
      logManager.refresh()
    }
  }

  // MARK: - Main column

  @ViewBuilder
  private var mainCards: some View {
    searchPreferencesCard
    requestLogsCard
    indexManagementCard
    privacyCard
  }

  private var searchPreferencesCard: some View {
    macosSettingsCard {
      VStack(alignment: .leading, spacing: 14) {
        documentsPerPageSetting
        macosSettingsDivider()
        macosSettingsRow(title: "Recent Query History",
                         description: "Removes the recent searches offered when you type a query.") {
          Button(action: clearRecentSearches) {
            Label(isCleared ? "Cleared" : "Clear Recent Searches",
                  systemImage: isCleared ? "checkmark" : "trash")
          }
          .buttonStyle(macosSettingsButtonStyle(confirmed: isCleared))
        }
      }
    }
  }

  private var documentsPerPageSetting: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Documents per page")
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(Color("TextColor"))

      macosSettingsWrappingRow(spacing: 10, rowSpacing: 8) {
        documentsPerPageField
        documentsPerPagePresets
      }

      Text(documentsPerPageInput == nil
           ? "Enter a whole number from \(SettingsDataManager.documentsPerPageRange.lowerBound) to \(SettingsDataManager.documentsPerPageRange.upperBound.formatted())."
           : "The number of documents shown on each page of search results. The default is \(SettingsDataManager.defaultDocumentsPerPage).")
        .font(.system(size: 11))
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var documentsPerPageField: some View {
    HStack(spacing: 8) {
      TextField("", text: $documentsPerPageText)
        .textFieldStyle(PlainTextFieldStyle())
        .multilineTextAlignment(.center)
        .padding(.horizontal, 6)
        .frame(width: 80, height: 28)
        .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
        .overlay(RoundedRectangle(cornerRadius: 5)
          .stroke(documentsPerPageFocused ? Color("LabelBackgroundBorder") : Color.clear, lineWidth: 1))
        .foregroundColor(Color("TextColor"))
        .focused($documentsPerPageFocused)
        .onSubmit(saveDocumentsPerPage)

      Button(action: saveDocumentsPerPage) {
        Text(documentsPerPageSaved ? "Saved" : "Save")
          .frame(minWidth: 44)
      }
      .buttonStyle(macosSettingsButtonStyle(confirmed: documentsPerPageSaved))
      .opacity(canSaveDocumentsPerPage || documentsPerPageSaved ? 1 : 0.5)
      .disabled(!canSaveDocumentsPerPage)
    }
  }

  // Quick picks, with Custom highlighted when the saved value isn't one of them
  private var documentsPerPagePresets: some View {
    let selectedPreset = SettingsDataManager.documentsPerPagePreset(matching: settingsManager.documentsPerPage)
    return HStack(spacing: 2) {
      ForEach(SettingsDataManager.documentsPerPagePresets, id: \.self) { preset in
        presetButton(String(preset), selected: selectedPreset == preset) {
          // A preset saves straight away, so the field doesn't need the focus
          documentsPerPageFocused = false
          if preset == settingsManager.documentsPerPage {
            documentsPerPageText = String(preset)
          } else if storeDocumentsPerPage(preset) {
            flashDocumentsPerPageSaved()
          }
        }
      }
      presetButton("Custom", selected: selectedPreset == nil) {
        documentsPerPageFocused = true
      }
    }
    .padding(2)
    .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
  }

  private func presetButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    macosSettingsSegment(title: title, selected: selected, action: action)
  }

  // The newest few requests, the rest are on the Request Logs page
  private var requestLogsCard: some View {
    let entries = logManager.newestFirst
    return macosSettingsCard(title: "Request Logs",
                             subtitle: "The last \(LogDataManager.limit) requests SearchOps made to your hosts, with what was sent and what came back.") {
      VStack(alignment: .leading, spacing: 12) {
        if entries.isEmpty {
          Text("No requests recorded yet.")
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
        } else {
          VStack(spacing: 4) {
            ForEach(entries.prefix(5), id: \.id) { event in
              macosRequestLogRow(event: event) {
                openLogs(selecting: event.id)
              }
            }
          }
        }

        HStack(spacing: 8) {
          Button(action: { openLogs() }) {
            Text(entries.isEmpty ? "View All" : "View All (\(entries.count))")
          }
          .buttonStyle(macosSettingsButtonStyle())
          .opacity(entries.isEmpty ? 0.5 : 1)
          .disabled(entries.isEmpty)

          Spacer(minLength: 8)

          Button(action: clearLogs) {
            Label(logsCleared ? "Cleared" : "Clear Logs",
                  systemImage: logsCleared ? "checkmark" : "trash")
          }
          .buttonStyle(macosSettingsButtonStyle(confirmed: logsCleared))
          .opacity(entries.isEmpty && !logsCleared ? 0.5 : 1)
          .disabled(entries.isEmpty)
        }
      }
    }
  }

  private var indexManagementCard: some View {
    macosSettingsCard(title: "Index Management",
                      subtitle: "Safeguards for changes made from Manage → Index and API.") {
      HStack(alignment: .center, spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text("Read Only Mode")
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(Color("TextColor"))
            macosSettingsBadge(text: indexReadOnly ? "Active" : "Inactive",
                               tone: indexReadOnly ? .positive : .neutral)
          }
          Text(indexReadOnly
               ? "When on, deleting documents from Manage → Index is disabled, and API only sends GET requests, searches, refresh, flush and cache clears."
               : "Read only is off. Deleting documents from Manage → Index, and sending any request from API, is now possible.")
            .font(.system(size: 11))
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 12)
        Toggle("Read Only Mode", isOn: $indexReadOnly)
          .labelsHidden()
          .toggleStyle(.switch)
      }
      .padding(14)
      .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
    }
  }

  private var privacyCard: some View {
    macosSettingsCard(title: "Zero Analytics Guarantee",
                      badge: macosSettingsBadge(text: "ENFORCED", tone: .accent)) {
      Text("Strictly no analytics, tracking or advertisements in SearchOps!")
        .font(.system(size: 12))
    }
  }

  // MARK: - Side column

  @ViewBuilder
  private var sideCards: some View {
    buildDetailsCard
    linksCard
    feedbackCard
  }

  private var buildDetailsCard: some View {
    macosSettingsCard(title: "Build Details") {
      VStack(spacing: 0) {
        macosKeyValueRow(label: "Version", value: BuildDetails.version) {
          macosSettingsBadge(text: BuildDetails.configuration)
        }
        macosSettingsDivider(color: Color("Button"))
        macosKeyValueRow(label: "Build", value: BuildDetails.buildNumber)
        macosSettingsDivider(color: Color("Button"))
        macosKeyValueRow(label: "App Commit", value: BuildDetails.commit ?? "Unknown") {
          if let commit = BuildDetails.commit {
            Button(action: { copyCommit(commit) }) {
              Image(systemName: commitCopied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 11))
                .foregroundColor(commitCopied ? Color("PositiveButton") : Color("TextSecondary"))
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Copy commit")
          }
        }
        macosSettingsDivider(color: Color("Button"))
        macosKeyValueRow(label: "Architecture", value: BuildDetails.architecture)
        macosSettingsDivider(color: Color("Button"))
        macosKeyValueRow(label: "macOS", value: BuildDetails.operatingSystem)
        macosSettingsDivider(color: Color("Button"))
        macosKeyValueRow(label: "Database",
                         value: RealmManager().inMemoryStoreRequested
                         ? "Realm · In-memory"
                         : "Realm · " + String(format: "%.2f", databaseSize) + " MB")
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 4)
      .background(RoundedRectangle(cornerRadius: 5).fill(Color("BackgroundAlt")))
    }
  }

  private var linksCard: some View {
    macosSettingsCard(title: "Open Source & Links") {
      VStack(spacing: 8) {
        macosLinkRow(icon: "folder",
                     title: "GitHub Repository",
                     subtitle: "mccaffers/search-ops",
                     destination: URL(string: "https://github.com/mccaffers/search-ops")!)
        macosLinkRow(icon: "hand.raised",
                     title: "Privacy Policy",
                     subtitle: "searchops.app",
                     destination: URL(string: "https://searchops.app")!)
      }
    }
  }

  private var feedbackCard: some View {
    macosSettingsCard(title: "Feedback & Support",
                      subtitle: "Please contact me if you have any issues or feedback.") {
      VStack(spacing: 8) {
        macosLinkRow(icon: "cat",
                     title: "mccaffers/search-ops",
                     actionLabel: "GitHub",
                     destination: URL(string: "https://github.com/mccaffers/search-ops")!)
        macosLinkRow(icon: "envelope",
                     title: "ryan@mccaffers.com",
                     actionLabel: "Email",
                     destination: URL(string: "mailto:ryan@mccaffers.com")!)
        macosLinkRow(icon: "at",
                     title: "@ryanmccaffers",
                     actionLabel: "Message on X",
                     destination: URL(string: "https://x.com/ryanmccaffers")!)
      }
    }
  }
}

// What this copy of the app is, read from the bundle and the running system
private enum BuildDetails {
  static var version: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }

  static var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
  }

  static var commit: String? {
    guard let hash = Bundle.main.appHash, !hash.isEmpty else { return nil }
    return hash
  }

  static var configuration: String {
#if DEBUG
    return "Debug"
#else
    return "Release"
#endif
  }

  static var architecture: String {
#if arch(arm64)
    return "Apple silicon"
#else
    return "Intel"
#endif
  }

  static var operatingSystem: String {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    let patch = version.patchVersion > 0 ? ".\(version.patchVersion)" : ""
    return "\(version.majorVersion).\(version.minorVersion)\(patch)"
  }
}

#endif
