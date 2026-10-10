// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
struct macosClusterHealthView: View {
  var host: HostDetails
  var onBack: () -> Void

  @State private var result: ClusterHealthResult? = nil
  @State private var loading: Bool = true
  @State private var lastUpdated: Date? = nil
  @State private var isBackHovered: Bool = false
  @State private var isRefreshHovered: Bool = false

  // Long shard lists are cut short, the API tab can list them all
  private let shardIssueLimit = 200
  private let headerControlHeight: CGFloat = 28

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      headerView

      if loading && result == nil {
        RepeatedPlaceholderView()
        Spacer()
      } else if let error = result?.error {
        errorView(error)
        Spacer()
      } else if let result = result, let health = result.health {
        ScrollView {
          VStack(alignment: .leading, spacing: 10) {
            statusCard(health)
            metricsGrid(health, stats: result.stats, statsError: result.statsError)
            if health.hasShardIssues || result.shardsError != nil {
              shardIssuesSection(result)
            }
            nodesSection(result)
          }
          .padding(.bottom, 10)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .task {
      await fetchHealth()
    }
  }

  // MARK: - Header

  private var headerView: some View {
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
        Text("Cluster health")
          .font(.system(size: 20, weight: .light))
        if !host.isInvalidated {
          Text([host.name, result?.info?.label].compactMap { $0 }.joined(separator: " · "))
            .font(.subheadline)
            .foregroundColor(Color("TextSecondary"))
            .lineLimit(1)
        }
      }

      Spacer()

      if let lastUpdated = lastUpdated {
        Text("Updated \(lastUpdated.formatted(date: .omitted, time: .standard))")
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
      }

      Button(action: {
        Task {
          await fetchHealth()
        }
      }) {
        Group {
          if loading && result != nil {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: "arrow.clockwise")
              .font(.system(size: 13, weight: .medium))
          }
        }
        .frame(width: headerControlHeight, height: headerControlHeight)
        .background(isRefreshHovered ? Color("ButtonHighlighted") : Color("Button"))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .disabled(loading)
      .onHover { hovering in
        isRefreshHovered = hovering
      }
      .help("Refresh cluster health")
    }
    .padding(.top, 10)
    .padding(.bottom, 2)
  }

  // MARK: - Status

  private func statusCard(_ health: ClusterHealthSummary) -> some View {
    HStack(alignment: .center, spacing: 14) {
      Circle()
        .fill(macosClusterHealthColors.status(health.status))
        .frame(width: 18, height: 18)

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 8) {
          Text(health.status.title)
            .font(.system(size: 18, weight: .semibold))
          if !health.clusterName.isEmpty {
            Text(health.clusterName)
              .font(.system(size: 13, design: .monospaced))
              .foregroundColor(Color("TextSecondary"))
              .lineLimit(1)
              .textSelection(.enabled)
          }
          if health.timedOut {
            macosClusterHealthBadge(text: "Timed out")
              .help("The health request timed out before the cluster answered fully")
          }
        }
        Text(health.status.explanation)
          .font(.system(size: 12))
          .foregroundColor(Color("TextSecondary"))
      }

      Spacer(minLength: 12)

      VStack(alignment: .trailing, spacing: 4) {
        Text(String(format: "%.1f%%", health.activeShardsPercent))
          .font(.system(size: 18, weight: .medium).monospacedDigit())
        Text("active shards")
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
        macosClusterHealthBar(percent: health.activeShardsPercent,
                              color: macosClusterHealthColors.status(health.status))
          .frame(width: 140)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .clipShape(.rect(cornerRadius: 5))
  }

  // MARK: - Metrics

  private func metricsGrid(_ health: ClusterHealthSummary, stats: ClusterStatsSummary?, statsError: String?) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 6)], spacing: 6) {
        macosClusterHealthTile(title: "Nodes", value: count(health.numberOfNodes),
                               detail: "\(count(health.numberOfDataNodes)) data")
        if let indexCount = stats?.indexCount {
          macosClusterHealthTile(title: "Indices", value: count(indexCount))
        }
        if let documentCount = stats?.documentCount {
          macosClusterHealthTile(title: "Documents", value: count(documentCount))
        }
        if let storeSize = stats?.storeSizeBytes {
          macosClusterHealthTile(title: "Store size", value: bytes(storeSize),
                                 detail: "Primaries and replicas")
        }
        if let used = stats?.fsUsedPercent, let total = stats?.fsTotalBytes, let available = stats?.fsAvailableBytes {
          macosClusterHealthTile(title: "Disk used", value: percent(used),
                                 detail: "\(bytes(available)) free of \(bytes(total))",
                                 percent: used)
        }
        if let heap = stats?.heapUsedPercent, let max = stats?.heapMaxBytes {
          macosClusterHealthTile(title: "JVM heap", value: percent(heap),
                                 detail: "of \(bytes(max))",
                                 percent: heap)
        }
        macosClusterHealthTile(title: "Active primary shards", value: count(health.activePrimaryShards))
        macosClusterHealthTile(title: "Active shards", value: count(health.activeShards))
        macosClusterHealthTile(title: "Relocating shards", value: count(health.relocatingShards),
                               tone: health.relocatingShards > 0 ? .warning : .normal)
        macosClusterHealthTile(title: "Initialising shards", value: count(health.initializingShards),
                               tone: health.initializingShards > 0 ? .warning : .normal)
        macosClusterHealthTile(title: "Unassigned shards", value: count(health.unassignedShards),
                               detail: health.delayedUnassignedShards > 0 ? "\(count(health.delayedUnassignedShards)) delayed" : nil,
                               tone: health.unassignedShards > 0 ? (health.status == .red ? .critical : .warning) : .normal)
        macosClusterHealthTile(title: "Pending tasks", value: count(health.pendingTasks),
                               detail: health.taskMaxWaitingMillis > 0 ? "Longest wait \(duration(health.taskMaxWaitingMillis))" : nil,
                               tone: health.pendingTasks > 0 ? .warning : .normal)
      }

      if let statsError = statsError {
        sectionNote("Cluster stats unavailable: \(statsError)")
      }
    }
  }

  // MARK: - Shards

  private func shardIssuesSection(_ result: ClusterHealthResult) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      sectionTitle("Shards needing attention",
                   count: result.shardIssues.isEmpty ? nil : result.shardIssues.count)

      if let shardsError = result.shardsError {
        sectionNote("Shard details unavailable: \(shardsError)")
      } else if result.shardIssues.isEmpty {
        sectionNote("Every shard has started since the health check")
      } else {
        VStack(spacing: 4) {
          ForEach(result.shardIssues.prefix(shardIssueLimit)) { issue in
            macosClusterShardIssueRow(issue: issue)
          }
        }
        if result.shardIssues.count > shardIssueLimit {
          sectionNote("Showing the first \(shardIssueLimit) of \(count(result.shardIssues.count)) shards")
        }
        if result.shardIssues.contains(where: { $0.state == "UNASSIGNED" }) {
          sectionNote("For why a shard can't be assigned, run GET /_cluster/allocation/explain from the API tab")
        }
      }
    }
    .padding(.top, 6)
  }

  // MARK: - Nodes

  private func nodesSection(_ result: ClusterHealthResult) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      sectionTitle("Nodes", count: result.nodes.isEmpty ? nil : result.nodes.count)

      if let nodesError = result.nodesError {
        sectionNote("Node details unavailable: \(nodesError)")
      } else if result.nodes.isEmpty {
        sectionNote("No nodes were returned for this host")
      } else {
        VStack(spacing: 4) {
          ForEach(result.nodes) { node in
            macosClusterNodeRow(node: node)
          }
        }
      }
    }
    .padding(.top, 6)
  }

  // MARK: - Shared pieces

  private func sectionTitle(_ title: String, count: Int?) -> some View {
    HStack(spacing: 6) {
      Text(title)
        .font(.system(size: 14, weight: .semibold))
      if let count = count {
        Text(self.count(count))
          .font(.system(size: 11, weight: .semibold))
          .padding(.horizontal, 7)
          .padding(.vertical, 2)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .foregroundColor(Color("TextSecondary"))
      }
    }
  }

  private func sectionNote(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 11))
      .foregroundColor(Color("TextSecondary"))
      .textSelection(.enabled)
      .fixedSize(horizontal: false, vertical: true)
  }

  private func errorView(_ error: ResponseError) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(.orange)
        Text(error.title)
          .font(.headline)
      }
      Text(error.message)
        .font(.subheadline)
        .foregroundColor(Color("TextSecondary"))
        .textSelection(.enabled)

      macosClusterHealthRetryButton {
        Task {
          await fetchHealth()
        }
      }
      .padding(.top, 4)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .clipShape(.rect(cornerRadius: 5))
  }

  private func count(_ value: Int) -> String {
    value.formatted(.number)
  }

  private func bytes(_ value: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: value, countStyle: .binary)
  }

  private func percent(_ value: Double) -> String {
    String(format: "%.0f%%", value)
  }

  private func duration(_ millis: Int) -> String {
    Duration.milliseconds(millis).formatted(.units(allowed: [.hours, .minutes, .seconds, .milliseconds], width: .narrow, maximumUnitCount: 2))
  }

  // MARK: - Loading

  private func fetchHealth() async {
    loading = true

    guard !host.isInvalidated else {
      result = ClusterHealthResult(error: ResponseError(title: "Host Invalidated",
                                                        message: "The host has been removed or invalidated.",
                                                        type: .critical))
      loading = false
      return
    }

    let fetched = await ClusterHealth.fetch(serverDetails: host.generateCopy())

    guard !Task.isCancelled else { return }

    result = fetched
    lastUpdated = fetched.error == nil ? Date() : nil
    loading = false
  }
}

enum macosClusterHealthColors {
  static func status(_ status: ClusterHealthStatus) -> Color {
    switch status {
    case .green: return Color("PositiveButton")
    case .yellow: return Color("Yellow")
    case .red: return Color("RedIcon")
    case .unknown: return Color("TextSecondary")
    }
  }

  /// Disk, heap and CPU usage turn amber at 75% and red at 90%
  static func usage(_ percent: Double) -> Color {
    if percent >= 90 { return Color("RedIcon") }
    if percent >= 75 { return Color("Yellow") }
    return Color("PositiveButton")
  }
}

struct macosClusterHealthBar: View {
  var percent: Double
  var color: Color

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 5)
          .fill(Color("BackgroundFixedShadow"))
        RoundedRectangle(cornerRadius: 5)
          .fill(color)
          .frame(width: geometry.size.width * CGFloat(min(max(percent, 0), 100) / 100))
      }
    }
    .frame(height: 5)
  }
}

struct macosClusterHealthTile: View {
  enum Tone {
    case normal, warning, critical
  }

  var title: String
  var value: String
  var detail: String? = nil
  var percent: Double? = nil
  var tone: Tone = .normal

  private var valueColor: Color {
    switch tone {
    case .normal: return Color("TextColor")
    case .warning: return Color("Yellow")
    case .critical: return Color("RedIcon")
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.system(size: 11))
        .foregroundColor(Color("TextSecondary"))
        .lineLimit(1)
      Text(value)
        .font(.system(size: 18, weight: .medium).monospacedDigit())
        .foregroundColor(valueColor)
        .lineLimit(1)
        .textSelection(.enabled)
      if let percent = percent {
        macosClusterHealthBar(percent: percent, color: macosClusterHealthColors.usage(percent))
          .padding(.vertical, 2)
      }
      if let detail = detail {
        Text(detail)
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(12)
    .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
    .background(Color("Button"))
    .clipShape(.rect(cornerRadius: 5))
  }
}

struct macosClusterNodeRow: View {
  var node: ClusterNode

  var body: some View {
    HStack(alignment: .center, spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text(node.name)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .textSelection(.enabled)
          if node.isElectedMaster {
            macosClusterHealthBadge(text: "Elected master")
              .help("This node is currently managing the cluster")
          }
        }
        Text([node.ip, node.version.map { "v\($0)" }].compactMap { $0 }.joined(separator: " · "))
          .font(.system(size: 11, design: .monospaced))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
          .textSelection(.enabled)
        if let roles = node.roles {
          (Text("Roles: ").foregroundColor(Color("TextSecondary")) + Text(roles).font(.system(size: 11, design: .monospaced)))
            .font(.system(size: 11))
            .help(node.roleNames.joined(separator: ", "))
        }
      }
      .frame(minWidth: 180, alignment: .leading)

      Spacer(minLength: 8)

      HStack(spacing: 12) {
        macosClusterNodeMetric(title: "Heap", percent: node.heapPercent)
        macosClusterNodeMetric(title: "RAM", percent: node.ramPercent)
        macosClusterNodeMetric(title: "CPU", percent: node.cpuPercent)
        macosClusterNodeMetric(title: "Disk", percent: node.diskUsedPercent)
        VStack(alignment: .leading, spacing: 3) {
          Text("Load 1m")
            .font(.system(size: 10))
            .foregroundColor(Color("TextSecondary"))
          Text(node.load1m.map { String(format: "%.2f", $0) } ?? "–")
            .font(.system(size: 12, weight: .medium).monospacedDigit())
        }
        .frame(width: 52, alignment: .leading)
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .clipShape(.rect(cornerRadius: 5))
  }
}

private struct macosClusterNodeMetric: View {
  var title: String
  var percent: Double?

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      HStack(spacing: 4) {
        Text(title)
          .font(.system(size: 10))
          .foregroundColor(Color("TextSecondary"))
        Spacer(minLength: 0)
        Text(percent.map { String(format: "%.0f%%", $0) } ?? "–")
          .font(.system(size: 12, weight: .medium).monospacedDigit())
      }
      macosClusterHealthBar(percent: percent ?? 0,
                            color: macosClusterHealthColors.usage(percent ?? 0))
    }
    .frame(width: 72)
  }
}

struct macosClusterShardIssueRow: View {
  var issue: ClusterShardIssue

  private var stateColor: Color {
    switch issue.state {
    case "UNASSIGNED": return issue.isPrimary ? Color("RedIcon") : Color("Yellow")
    default: return Color("TextSecondary")
    }
  }

  var body: some View {
    HStack(spacing: 10) {
      Text(issue.state.capitalized)
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(stateColor)
        .frame(width: 80, alignment: .leading)

      Text(issue.index)
        .font(.system(size: 12, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)
        .textSelection(.enabled)

      Text("shard \(issue.shard) · \(issue.isPrimary ? "primary" : "replica")")
        .font(.system(size: 11))
        .foregroundColor(Color("TextSecondary"))
        .lineLimit(1)

      Spacer(minLength: 8)

      if let reason = issue.unassignedReason {
        Text(reason)
          .font(.system(size: 11, design: .monospaced))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
          .help("Why the shard was last unassigned")
      }
      if let node = issue.node {
        Text(node)
          .font(.system(size: 11))
          .foregroundColor(Color("TextSecondary"))
          .lineLimit(1)
          .truncationMode(.middle)
      }
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Button"))
    .clipShape(.rect(cornerRadius: 5))
  }
}

private struct macosClusterHealthBadge: View {
  var text: String

  var body: some View {
    Text(text)
      .font(.system(size: 10, weight: .semibold))
      .padding(.horizontal, 6)
      .padding(.vertical, 1)
      .background(Color("BackgroundFixedShadow"))
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .foregroundColor(Color("TextSecondary"))
  }
}

private struct macosClusterHealthRetryButton: View {
  var action: () -> Void
  @State private var isHovered: Bool = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        Image(systemName: "arrow.clockwise")
        Text("Retry")
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(isHovered ? Color("ButtonHighlighted") : Color("BackgroundAlt"))
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

#Preview {
  let host = HostDetails()
  host.name = "Production Cluster"
  return macosClusterHealthView(host: host, onBack: {})
    .frame(width: 800, height: 600)
    .padding()
}
#endif
