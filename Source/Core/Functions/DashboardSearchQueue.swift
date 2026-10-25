// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// Lets a few dashboard panels search at once and queues the rest, so opening a big dashboard doesn't send every
/// search to the cluster together. Searches start in the order they ask.
@MainActor
public final class DashboardSearchQueue {
  public static let shared = DashboardSearchQueue(limit: 4)

  public let limit: Int
  /// Searches holding a place
  public private(set) var running = 0
  private var waiting: [(id: UUID, continuation: CheckedContinuation<Bool, Never>)] = []

  public var waitingCount: Int { waiting.count }

  public init(limit: Int) {
    self.limit = max(1, limit)
  }

  /// Runs `work` once a place is free. Returns nil without running it when the task is cancelled while waiting,
  /// eg. the panel was closed or refreshed again.
  public func run<T>(_ work: () async -> T) async -> T? {
    guard await acquire() else { return nil }
    defer { release() }
    return await work()
  }

  /// Waits for a place. False when cancelled first, and then no place is held.
  func acquire() async -> Bool {
    if Task.isCancelled { return false }
    if running < limit {
      running += 1
      return true
    }
    let id = UUID()
    return await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        waiting.append((id, continuation))
      }
    } onCancel: {
      Task { @MainActor in
        self.cancelWaiting(id)
      }
    }
  }

  /// Hands the place to the next search waiting, or frees it
  func release() {
    if waiting.isEmpty {
      running -= 1
    } else {
      waiting.removeFirst().continuation.resume(returning: true)
    }
  }

  private func cancelWaiting(_ id: UUID) {
    guard let index = waiting.firstIndex(where: { $0.id == id }) else { return }
    waiting.remove(at: index).continuation.resume(returning: false)
  }
}
