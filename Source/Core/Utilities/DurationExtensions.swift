// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 13, *)
@available(iOS 16, *)
extension Duration {
  /// A short label for a request's round-trip time: whole milliseconds under a second ("42 ms"),
  /// otherwise seconds to two decimal places ("1.23 s").
  public var latencyLabel: String {
    let milliseconds = Double(components.seconds) * 1000
      + Double(components.attoseconds) / 1e15
    if milliseconds < 1000 {
      return String(format: "%.0f ms", milliseconds)
    }
    return String(format: "%.2f s", milliseconds / 1000)
  }

  /// Whether a request took longer than one second, so its latency is worth flagging.
  public var isSlowLatency: Bool {
    self > .seconds(1)
  }
}
