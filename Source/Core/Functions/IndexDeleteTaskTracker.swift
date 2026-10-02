// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Combine

public enum DeleteOperationKind: String, Identifiable, Sendable {
  case all
  case byAge

  public var id: String { rawValue }
}

/// A delete is tracked per host and index, only one may be active at a time
public struct DeleteOperationKey: Hashable, Sendable {
  public let hostId: UUID
  public let index: String

  public init(hostId: UUID, index: String) {
    self.hostId = hostId
    self.index = index
  }
}

public enum DeleteOperationState: Equatable {
  case submitting
  case running(taskId: String, progress: DeleteTaskProgress?)
  case cancelling(taskId: String, progress: DeleteTaskProgress?)
  case finished(DeleteByQueryResult)
  /// Progress can no longer be read, the task may still be running on the cluster
  case untracked(taskId: String, message: String)

  public var isActive: Bool {
    switch self {
    case .submitting, .running, .cancelling:
      return true
    case .finished, .untracked:
      return false
    }
  }

  public var progress: DeleteTaskProgress? {
    switch self {
    case .running(_, let progress), .cancelling(_, let progress):
      return progress
    default:
      return nil
    }
  }
}

public struct DeleteOperation: Equatable {
  public var kind: DeleteOperationKind
  public var state: DeleteOperationState
  /// Non-fatal note shown alongside the operation, e.g. a rejected cancel request
  public var notice: String?

  public init(kind: DeleteOperationKind, state: DeleteOperationState, notice: String? = nil) {
    self.kind = kind
    self.state = state
    self.notice = notice
  }
}

/// Owns delete-by-query tasks so they keep polling after the views that started them are gone
@MainActor
public final class IndexDeleteTaskTracker: ObservableObject {
  public static let shared = IndexDeleteTaskTracker()

  public typealias Submitter = (HostDetails) async -> DeleteTaskSubmission
  public typealias StatusFetcher = (HostDetails, String) async -> DeleteTaskStatus
  public typealias Canceller = (HostDetails, String) async -> ResponseError?
  public typealias Sleeper = (UInt64) async -> Void

  @Published public private(set) var operations: [DeleteOperationKey: DeleteOperation] = [:]
  /// Incremented each time an operation finishes, observers reload stats when it changes
  @Published public private(set) var completions: [DeleteOperationKey: Int] = [:]

  private var hosts: [DeleteOperationKey: HostDetails] = [:]
  private var pollTasks: [DeleteOperationKey: Task<Void, Never>] = [:]

  private let fetchStatus: StatusFetcher
  private let cancelTask: Canceller
  private let sleep: Sleeper
  private let initialPollInterval: UInt64
  private let maxPollInterval: UInt64
  private let maxPollFailures: Int

  public init(
    fetchStatus: @escaping StatusFetcher = { host, taskId in
      await IndexManagementService.fetchDeleteTaskStatus(serverDetails: host, taskId: taskId)
    },
    cancelTask: @escaping Canceller = { host, taskId in
      await IndexManagementService.cancelDeleteTask(serverDetails: host, taskId: taskId)
    },
    sleep: @escaping Sleeper = { nanoseconds in
      try? await Task.sleep(nanoseconds: nanoseconds)
    },
    initialPollInterval: UInt64 = 1_000_000_000,
    maxPollInterval: UInt64 = 5_000_000_000,
    maxPollFailures: Int = 3
  ) {
    self.fetchStatus = fetchStatus
    self.cancelTask = cancelTask
    self.sleep = sleep
    self.initialPollInterval = initialPollInterval
    self.maxPollInterval = maxPollInterval
    self.maxPollFailures = maxPollFailures
  }

  public static func key(host: HostDetails, index: String) -> DeleteOperationKey {
    DeleteOperationKey(hostId: host.id, index: index)
  }

  public func operation(for key: DeleteOperationKey) -> DeleteOperation? {
    operations[key]
  }

  public func isActive(_ key: DeleteOperationKey) -> Bool {
    operations[key]?.state.isActive == true
  }

  /// Starts a delete, returns false when one is already active for this host and index
  @discardableResult
  public func start(
    kind: DeleteOperationKind,
    host: HostDetails,
    index: String,
    submit: @escaping Submitter
  ) -> Bool {
    guard !host.isInvalidated else { return false }
    let key = Self.key(host: host, index: index)
    guard !isActive(key) else { return false }

    let detachedHost = host.generateCopy()
    hosts[key] = detachedHost
    operations[key] = DeleteOperation(kind: kind, state: .submitting)

    pollTasks[key] = Task { [weak self] in
      let submission = await submit(detachedHost)
      guard let self = self else { return }

      switch submission {
      case .failed(let result):
        self.finish(key, result: result)
      case .started(let taskId):
        self.update(key) { $0.state = .running(taskId: taskId, progress: nil) }
        await self.poll(key, taskId: taskId, host: detachedHost)
      }
    }
    return true
  }

  /// Asks the cluster to cancel a running task, the final state still arrives through polling
  public func cancel(_ key: DeleteOperationKey) {
    guard case .running(let taskId, let progress) = operations[key]?.state,
          let host = hosts[key] else {
      return
    }

    update(key) {
      $0.state = .cancelling(taskId: taskId, progress: progress)
      $0.notice = nil
    }

    Task { [weak self] in
      let error = await self?.cancelTask(host, taskId)
      guard let self = self, let error = error else { return }
      // Cancel was rejected, keep tracking the still-running task
      if case .cancelling(let id, let latest) = self.operations[key]?.state, id == taskId {
        self.update(key) {
          $0.state = .running(taskId: taskId, progress: latest)
          $0.notice = "Cancel failed: \(error.message)"
        }
      }
    }
  }

  /// Removes a finished or untracked operation so its result is no longer shown
  public func clear(_ key: DeleteOperationKey) {
    guard let op = operations[key], !op.state.isActive else { return }
    operations[key] = nil
    hosts[key] = nil
    pollTasks[key] = nil
  }

  /// Waits for the operation's submit and poll loop to end, used by tests
  func waitUntilSettled(_ key: DeleteOperationKey) async {
    await pollTasks[key]?.value
  }

  // MARK: - Polling

  private func poll(_ key: DeleteOperationKey, taskId: String, host: HostDetails) async {
    var interval = initialPollInterval
    var consecutiveFailures = 0

    while !Task.isCancelled {
      await sleep(interval)
      guard !Task.isCancelled else { return }

      switch await fetchStatus(host, taskId) {
      case .running(let progress):
        consecutiveFailures = 0
        update(key) { op in
          if case .cancelling = op.state {
            op.state = .cancelling(taskId: taskId, progress: progress)
          } else {
            op.state = .running(taskId: taskId, progress: progress)
          }
        }
        interval = min(interval + initialPollInterval, maxPollInterval)

      case .completed(let result):
        finish(key, result: result)
        return

      case .untrackable(let error):
        markUntracked(key, taskId: taskId, reason: error.message)
        return

      case .pollFailed(let error):
        consecutiveFailures += 1
        if consecutiveFailures >= maxPollFailures {
          markUntracked(key, taskId: taskId, reason: error.message)
          return
        }
      }
    }
  }

  private func finish(_ key: DeleteOperationKey, result: DeleteByQueryResult) {
    update(key) {
      $0.state = .finished(result)
      $0.notice = nil
    }
    completions[key, default: 0] += 1
  }

  private func markUntracked(_ key: DeleteOperationKey, taskId: String, reason: String) {
    update(key) {
      $0.state = .untracked(
        taskId: taskId,
        message: "Task \(taskId) may still be running on the cluster. Progress can't be read: \(reason)"
      )
      $0.notice = nil
    }
    // Documents may already have been removed
    completions[key, default: 0] += 1
  }

  private func update(_ key: DeleteOperationKey, _ change: (inout DeleteOperation) -> Void) {
    guard var op = operations[key] else { return }
    change(&op)
    operations[key] = op
  }
}
