// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)
struct macosDevelopView: View {
  @Binding var fullScreen : Bool
  @ObservedObject var serverObjects: HostsDataManager
  @ObservedObject var hostsUpdated: HostUpdatedNotifier

  @AppStorage("devConsole.requestText") private var requestText: String = "GET /_cluster/health"
  @AppStorage("devConsole.selectedHostId") private var selectedHostId: String = ""
  // Read only mode is toggled in Settings and blocks requests that could change data
  @AppStorage(IndexManagementPreferences.readOnlyKey) private var isReadOnly: Bool = IndexManagementPreferences.readOnlyDefault

  @State private var isSending = false
  @State private var sendTask: Task<Void, Never>? = nil
  @State private var pendingRequest: DevConsoleRequest? = nil
  @State private var result: DevConsoleResult? = nil
  @State private var parseError: String? = nil
  @State private var isCopied = false
  @State private var isCurlCopied = false
  @State private var showTemplates = false
  @State private var templateHost: HostDetails? = nil

  private var activeHosts: [HostDetails] {
    serverObjects.items.filter { !$0.isInvalidated }
  }

  // Falls back to the first host if the stored host has been deleted
  private var selectedHost: HostDetails? {
    activeHosts.first(where: { $0.id.uuidString == selectedHostId }) ?? activeHosts.first
  }

  var body: some View {
    ZStack {
      HStack(spacing: 5) {
        requestPanel
        responsePanel
      }

      if showTemplates, let host = templateHost {
        RoundedRectangle(cornerRadius: 5).fill(Color.black).opacity(0.4)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .contentShape(Rectangle())
          .onTapGesture {
            closeTemplates()
          }

        GeometryReader { proxy in
          macosDevTemplatesView(host: host,
                                initialIndex: DevConsoleTemplate.index(fromRequestText: requestText) ?? "",
                                onUse: { template in
                                  requestText = template
                                  // The response belongs to the previous request
                                  parseError = nil
                                  closeTemplates()
                                },
                                onClose: closeTemplates)
          .frame(width: proxy.size.width * 0.8, height: proxy.size.height * 0.8)
          .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
      }
    }
    .padding(.leading, 3)
    .padding(.trailing, 5)
    .padding(.bottom, 5)
    .padding(.top, fullScreen ? 5 : 0)
    .onAppear {
      serverObjects.refresh()
    }
    .onChange(of: hostsUpdated.updated) { _ in
      serverObjects.refresh()
    }
  }

  // MARK: Request

  private var requestPanel: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text("API")
          .font(.system(size: 22, weight: .light))

        Spacer()

        if isReadOnly {
          ReadOnlyPadlockButton(detail: "Requests that could change data are blocked. GET requests, searches, refresh, flush and cache clears still work. Turn it off in Settings.")
        }

        templatesButton

        hostPicker

        // Doubles as the cancel button while a request is in flight
        Button(action: isSending ? cancel : send) {
          HStack(spacing: 4) {
            Image(systemName: isSending ? "stop.fill" : "play.fill")
              .font(.system(size: 11))
            Text(isSending ? "Cancel" : "Send")
              .font(.system(size: 12, weight: .medium))
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(Color(isSending ? "WarnButton" : "macosGreenButton"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .keyboardShortcut(.return, modifiers: .command)
        // The templates popup has its own ⌘↩
        .disabled(showTemplates || (!isSending && selectedHost == nil))
        .help(isSending ? "Cancel request (⌘↩)" : "Send request (⌘↩)")
      }
      .padding(.top, 10)

      macosCodeEditor(text: $requestText, isInteractive: !showTemplates)
        .background(Color("BackgroundAlt"))
        .clipShape(.rect(cornerRadius: 5))

      if let parseError = parseError {
        HStack(alignment: .top, spacing: 6) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(Color("WarnText"))
          Text(parseError)
            .font(.system(size: 12))
            .foregroundColor(Color("WarnText"))
            .textSelection(.enabled)
          Spacer()
        }
      }

      Text("First line is the method and path, eg. GET /_cat/indices, followed by an optional JSON body")
        .font(.system(size: 11))
        .foregroundColor(Color("TextSecondary"))
        .padding(.bottom, 8)
    }
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("BackgroundFixedShadow"))
    .clipShape(.rect(cornerRadius: 5))
  }

  private var templatesButton: some View {
    Button(action: {
      if showTemplates {
        closeTemplates()
      } else {
        openTemplates()
      }
    }) {
      HStack(spacing: 4) {
        Image(systemName: "square.grid.2x2")
          .font(.system(size: 11))
        Text("Templates")
          .font(.system(size: 12))
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(Color(showTemplates ? "macosGreenButton" : "Button"))
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(selectedHost == nil)
    .help("Start from a template built from the index mapping")
  }

  @ViewBuilder
  private var hostPicker: some View {
    if activeHosts.isEmpty {
      Text("No hosts configured")
        .font(.system(size: 12))
        .foregroundColor(Color("TextSecondary"))
    } else {
      Menu {
        ForEach(activeHosts, id: \.id) { host in
          Button(action: {
            selectedHostId = host.id.uuidString
          }) {
            if host.id == selectedHost?.id {
              Label(host.name, systemImage: "checkmark")
            } else {
              Text(host.name)
            }
          }
        }
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "server.rack")
            .font(.system(size: 11))
          Text(selectedHost?.name ?? "Select host")
            .font(.system(size: 12))
            .lineLimit(1)
        }
      }
      .menuStyle(.borderlessButton)
      .fixedSize()
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(Color("Button"))
      .clipShape(RoundedRectangle(cornerRadius: 5))
    }
  }

  // MARK: Response

  private var responsePanel: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text("Response")
          .font(.system(size: 22, weight: .light))

        Spacer()

        if let result = result {
          if result.status > 0 {
            Text("\(result.status)")
              .font(.system(size: 11, weight: .semibold, design: .monospaced))
              .padding(.horizontal, 6)
              .padding(.vertical, 3)
              .foregroundColor(HTTPStatusColors.getStatusColor(input: result.status))
              .background(HTTPStatusColors.getStatusColor(input: result.status).opacity(0.18))
              .clipShape(RoundedRectangle(cornerRadius: 4))
          }

          if let duration = result.duration {
            Text(duration.latencyLabel)
              .font(.system(size: 11))
              .foregroundColor(Color("TextSecondary"))
          }

          Button(action: copyResponse) {
            HStack(spacing: 4) {
              Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 11))
              Text(isCopied ? "Copied!" : "Copy")
                .font(.system(size: 11))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("Button"))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .disabled(result.body.isEmpty)
        }

        Button(action: copyCurl) {
          HStack(spacing: 4) {
            Image(systemName: isCurlCopied ? "checkmark" : "terminal")
              .font(.system(size: 11))
            Text(isCurlCopied ? "Copied!" : "cURL")
              .font(.system(size: 11))
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedHost == nil)
        .help("Copy the request in the editor as a curl command, credentials are left as placeholders")
      }
      .padding(.top, 10)

      if let result = result {
        Text("\(result.sentMethod.rawValue) \(result.path)")
          .font(.system(size: 11, design: .monospaced))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
          .truncationMode(.middle)
          .textSelection(.enabled)
      }

      responseBody
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundAlt"))
        .clipShape(.rect(cornerRadius: 5))
        .padding(.bottom, 8)
    }
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("BackgroundFixedShadow"))
    .clipShape(.rect(cornerRadius: 5))
  }

  @ViewBuilder
  private var responseBody: some View {
    if isSending {
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if let result = result {
      if let errorMessage = result.errorMessage {
        VStack(spacing: 8) {
          Image(systemName: result.isCancelled ? "xmark.circle" : "exclamationmark.triangle")
            .font(.system(size: 28))
            .foregroundColor(Color(result.isCancelled ? "TextSecondary" : "WarnText"))
          Text(errorMessage)
            .font(.system(size: 13))
            .multilineTextAlignment(.center)
            .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if result.body.isEmpty {
        Text("Empty response")
          .font(.system(size: 13))
          .foregroundColor(Color("TextSecondary"))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        SelectableReadOnlyTextView(text: result.body, showsScrollersWhenOverflowing: true)
      }
    } else if parseError != nil {
      VStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle")
          .font(.system(size: 28))
          .foregroundColor(Color("WarnText"))
        Text("Request not sent, fix the error in the editor")
          .font(.system(size: 13))
          .foregroundColor(Color("TextSecondary"))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      VStack(spacing: 8) {
        Image(systemName: "ellipsis.curlybraces")
          .font(.system(size: 28))
          .foregroundColor(Color("TextSecondary"))
        Text("Send a request to see the response")
          .font(.system(size: 13))
          .foregroundColor(Color("TextSecondary"))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  // MARK: Actions

  private func send() {
    // Copy the host, the Realm object can be invalidated while the request is in flight
    guard !isSending, let host = selectedHost?.generateCopy() else { return }

    switch DevConsoleParser.parse(requestText) {
    case .failure(let error):
      // Clear the last response so it isn't mistaken for this request's
      parseError = error.localizedDescription
      result = nil
    case .success(let request):
      // Checked here too so the reason shows under the editor, the service also refuses it
      if isReadOnly, let reason = DevConsoleReadOnlyPolicy.blockedReason(for: request) {
        parseError = reason
        result = nil
        return
      }
      parseError = nil
      isSending = true
      isCopied = false
      pendingRequest = request
      sendTask = Task {
        let response = await DevConsoleService.send(host: host, request: request, readOnly: isReadOnly)
        // A cancelled request has already updated the UI, and a newer one may be in flight
        guard !Task.isCancelled else { return }
        result = response
        isSending = false
        sendTask = nil
        pendingRequest = nil
      }
    }
  }

  private func cancel() {
    guard isSending else { return }
    // Cancelling the task cancels its URLSession request
    sendTask?.cancel()
    sendTask = nil
    if let request = pendingRequest {
      result = .cancelled(request)
    }
    pendingRequest = nil
    isSending = false
  }

  private func openTemplates() {
    // Copy the host, the Realm object can be invalidated while the popup loads the mapping
    guard let host = selectedHost?.generateCopy() else { return }
    templateHost = host
    showTemplates = true
  }

  private func closeTemplates() {
    showTemplates = false
    templateHost = nil
  }

  private func copyResponse() {
    guard let body = result?.body, !body.isEmpty else { return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(body, forType: .string)
    isCopied = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      isCopied = false
    }
  }

  private func copyCurl() {
    guard let host = selectedHost else { return }
    switch DevConsoleParser.parse(requestText) {
    case .failure(let error):
      parseError = error.localizedDescription
    case .success(let request):
      parseError = nil
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(DevConsoleCurlExporter.command(for: request, host: host),
                                     forType: .string)
      isCurlCopied = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        isCurlCopied = false
      }
    }
  }
}

#Preview {
  macosDevelopView(fullScreen: .constant(false),
                   serverObjects: HostsDataManager(),
                   hostsUpdated: HostUpdatedNotifier())
}
#endif
