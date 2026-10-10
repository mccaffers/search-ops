// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// A data view as views see it. It's a plain value, so it's never invalidated.
public struct DataView: Identifiable, Equatable, Hashable {
  public var id: UUID
  public var hostId: UUID
  public var name: String
  public var pattern: String
  public var timeField: String
  /// Field path to label, eg. "completedAttempts.maePoints.p50": "MAE p50 (points)"
  public var labels: [String: String]
  public var createdDate: Date
  public var updatedDate: Date

  public init(id: UUID = UUID(),
              hostId: UUID,
              name: String = "",
              pattern: String = "",
              timeField: String = "",
              labels: [String: String] = [:],
              createdDate: Date = Date.now,
              updatedDate: Date = Date.now) {
    self.id = id
    self.hostId = hostId
    self.name = name
    self.pattern = pattern
    self.timeField = timeField
    self.labels = labels
    self.createdDate = createdDate
    self.updatedDate = updatedDate
  }

  /// Trims the name, pattern and labels, and drops empty labels
  public func normalized() -> DataView {
    var copy = self
    copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    // Spaces around commas would end up in the request URL. Empty entries stay, so validation still sees them
    copy.pattern = pattern
      .split(separator: ",", omittingEmptySubsequences: false)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .joined(separator: ",")
    copy.timeField = timeField.trimmingCharacters(in: .whitespacesAndNewlines)
    var cleaned: [String: String] = [:]
    for (field, label) in labels {
      let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
      if !field.isEmpty && !trimmed.isEmpty {
        cleaned[field] = trimmed
      }
    }
    copy.labels = cleaned
    return copy
  }

  /// True when the user-editable parts differ, ignoring whitespace and empty labels
  public func hasChanges(comparedTo other: DataView) -> Bool {
    let lhs = normalized()
    let rhs = other.normalized()
    return lhs.name != rhs.name
      || lhs.pattern != rhs.pattern
      || lhs.timeField != rhs.timeField
      || lhs.labels != rhs.labels
  }
}

public enum DataViewError: Error, Equatable {
  case nameEmpty
  case nameTaken
  case patternEmpty
  case patternInvalid(String)
  case notFound
  case storageUnavailable

  public var message: String {
    switch self {
    case .nameEmpty:
      return "Enter a name."
    case .nameTaken:
      return "This host already has a data view with that name."
    case .patternEmpty:
      return "Enter an index pattern, eg. logs-*"
    case .patternInvalid(let reason):
      return reason
    case .notFound:
      return "This data view no longer exists."
    case .storageUnavailable:
      return "The local database isn't available."
    }
  }
}
