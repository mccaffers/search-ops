// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
struct macosManageUsersView: View {
  var host: HostDetails
  var onBack: () -> Void

  @State private var users: [ClusterUser] = []
  @State private var source: ClusterUserSource? = nil
  @State private var loading: Bool = true
  @State private var usersError: ResponseError? = nil
  @State private var searchText: String = ""
  @State private var isBackHovered: Bool = false

  var filteredUsers: [ClusterUser] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return users }
    return users.filter { user in
      ([user.username, user.fullName, user.email, user.description].compactMap { $0 } + user.roles + user.backendRoles)
        .contains { $0.localizedCaseInsensitiveContains(query) }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Top-left header with back button and user count
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
            Text("Users")
              .font(.system(size: 20, weight: .light))
            if !loading && usersError == nil {
              Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(users.count)" : "\(filteredUsers.count) / \(users.count)")
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color("Button"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .foregroundColor(Color("TextSecondary"))
            }
          }
          if !host.isInvalidated {
            Text(source.map { "\(host.name) · \($0.rawValue) security" } ?? host.name)
              .font(.subheadline)
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
          }
        }

        Spacer()
      }
      .padding(.top, 10)
      .padding(.bottom, 2)

      // Content Area
      if loading {
        RepeatedPlaceholderView()
        Spacer()
      } else if let usersError = usersError {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
            Text(usersError.title)
              .font(.headline)
          }
          Text(usersError.message)
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .textSelection(.enabled)

          Button(action: {
            Task {
              await fetchUsers()
            }
          }) {
            HStack(spacing: 4) {
              Image(systemName: "arrow.clockwise")
              Text("Retry")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BackgroundFixedShadow"))
        .clipShape(.rect(cornerRadius: 5))

        Spacer()
      } else if users.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "person.2.slash")
            .font(.system(size: 28))
            .foregroundColor(Color("TextSecondary"))
          Text("No users found")
            .font(.headline)
          Text("No users were returned for this host.")
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
      } else {
        // Search filter
        HStack(spacing: 6) {
          Image(systemName: "magnifyingglass")
            .foregroundColor(Color("TextSecondary"))
            .font(.system(size: 12))

          TextField("Filter users...", text: $searchText)
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 13))
            .disableAutocorrection(true)
            .onExitCommand {
              searchText = ""
            }

          if !searchText.isEmpty {
            Button(action: { searchText = "" }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(Color("TextSecondary"))
                .font(.system(size: 12))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Clear filter")
          }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color("Button"))
        .clipShape(RoundedRectangle(cornerRadius: 5))

        if filteredUsers.isEmpty {
          VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 24))
              .foregroundColor(Color("TextSecondary"))
            Text("No matching users")
              .font(.headline)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.top, 40)
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
              ForEach(filteredUsers) { user in
                macosManageUserRowView(user: user)
              }
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .task {
      await fetchUsers()
    }
  }

  private func fetchUsers() async {
    loading = true
    usersError = nil
    users = []
    source = nil

    guard !host.isInvalidated else {
      usersError = ResponseError(title: "Host Invalidated", message: "The host has been removed or invalidated.", type: .critical)
      loading = false
      return
    }

    let result = await ClusterUsers.listUsers(serverDetails: host.generateCopy())

    guard !Task.isCancelled else { return }

    if let error = result.error {
      usersError = error
    } else {
      users = result.users
      source = result.source
    }
    loading = false
  }
}

struct macosManageUserRowView: View {
  var user: ClusterUser

  private var detail: String? {
    let parts = [user.fullName, user.email, user.description].compactMap { $0 }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: user.enabled ? "person.crop.circle" : "person.crop.circle.badge.xmark")
        .font(.system(size: 16))
        .foregroundColor(user.enabled ? Color.accentColor : Color("TextSecondary"))
        .frame(width: 22)
        .padding(.top, 1)

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(user.username)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .textSelection(.enabled)
          if user.reserved {
            macosManageUserBadge(text: "Reserved")
              .help("Built-in user managed by the cluster")
          }
          if !user.enabled {
            macosManageUserBadge(text: "Disabled")
          }
        }

        if let detail = detail {
          Text(detail)
            .font(.caption)
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
            .truncationMode(.tail)
        }

        if !user.roles.isEmpty || !user.backendRoles.isEmpty {
          macosManageUserRolesText(label: "Roles", values: user.roles)
          macosManageUserRolesText(label: "Backend roles", values: user.backendRoles)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .clipShape(.rect(cornerRadius: 5))
  }
}

private struct macosManageUserBadge: View {
  var text: String

  var body: some View {
    Text(text)
      .font(.system(size: 10, weight: .semibold))
      .padding(.horizontal, 6)
      .padding(.vertical, 1)
      .background(Color("BackgroundFixedShadow"))
      .clipShape(Capsule())
      .foregroundColor(Color("TextSecondary"))
  }
}

private struct macosManageUserRolesText: View {
  var label: String
  var values: [String]

  var body: some View {
    if !values.isEmpty {
      (Text("\(label): ").foregroundColor(Color("TextSecondary")) + Text(values.joined(separator: ", ")))
        .font(.system(size: 11))
        .lineLimit(2)
        .textSelection(.enabled)
    }
  }
}

#Preview {
  let host = HostDetails()
  host.name = "Production Cluster"
  return macosManageUsersView(host: host, onBack: {})
    .frame(width: 400, height: 500)
    .padding()
}
#endif
