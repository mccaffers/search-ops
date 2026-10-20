// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing

@testable import Search_Ops

@MainActor
struct DashboardSearchQueueTests {

  /// Lets queued tasks run until `count` are waiting. False if they never do, so a broken queue fails the test
  /// instead of hanging it.
  private func waitUntil(_ queue: DashboardSearchQueue, isWaiting count: Int) async -> Bool {
    for _ in 0..<10_000 where queue.waitingCount < count {
      await Task.yield()
    }
    return queue.waitingCount >= count
  }

  @Test func placesAreHandedOutInOrderUpToTheLimit() async throws {
    let queue = DashboardSearchQueue(limit: 2)
    #expect(await queue.acquire())
    #expect(await queue.acquire())
    #expect(queue.running == 2)

    var started: [Int] = []
    let third = Task { @MainActor in
      if await queue.acquire() { started.append(3) }
    }
    try #require(await waitUntil(queue, isWaiting: 1))
    let fourth = Task { @MainActor in
      if await queue.acquire() { started.append(4) }
    }
    try #require(await waitUntil(queue, isWaiting: 2))
    #expect(started.isEmpty)

    queue.release()
    await third.value
    #expect(started == [3])
    // The place went straight to the next search, so as many are running
    #expect(queue.running == 2)

    queue.release()
    await fourth.value
    #expect(started == [3, 4])

    queue.release()
    queue.release()
    #expect(queue.running == 0)
  }

  @Test func aSearchCancelledWhileWaitingGivesUpWithoutAPlace() async throws {
    let queue = DashboardSearchQueue(limit: 1)
    #expect(await queue.acquire())

    let waiter = Task { @MainActor in await queue.acquire() }
    try #require(await waitUntil(queue, isWaiting: 1))
    waiter.cancel()

    #expect(await waiter.value == false)
    #expect(queue.waitingCount == 0)
    queue.release()
    #expect(queue.running == 0)
  }

  @Test func runFreesItsPlaceAfterTheWork() async {
    let queue = DashboardSearchQueue(limit: 1)
    let result = await queue.run { 42 }
    #expect(result == 42)
    #expect(queue.running == 0)
  }

  @Test func runSkipsTheWorkWhenAlreadyCancelled() async {
    let queue = DashboardSearchQueue(limit: 1)
    var ran = false
    let task = Task { @MainActor in
      withUnsafeCurrentTask { $0?.cancel() }
      return await queue.run { ran = true }
    }
    #expect(await task.value == nil)
    #expect(!ran)
    #expect(queue.running == 0)
  }

  @Test func aLimitBelowOneStillLetsOneRun() {
    #expect(DashboardSearchQueue(limit: 0).limit == 1)
  }
}
