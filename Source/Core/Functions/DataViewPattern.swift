// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// Index patterns for data views: `*` wildcards and comma-separated lists, eg. "logs-*,metrics-*"
public enum DataViewPattern {

  // As IndexManagementService.validateIndexName, less "*" and "," which patterns need
  static let forbidden: Set<Character> = ["?", "/", "\\", "\"", "<", ">", "|", "#", ":", " "]

  /// The comma-separated parts, trimmed, without empty ones
  public static func parts(of pattern: String) -> [String] {
    return pattern
      .split(separator: ",", omittingEmptySubsequences: false)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
  }

  /// nil when the pattern can be saved
  public static func validate(_ pattern: String) -> DataViewError? {
    let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return .patternEmpty
    }

    let rawParts = trimmed
      .split(separator: ",", omittingEmptySubsequences: false)
      .map { $0.trimmingCharacters(in: .whitespaces) }
    if rawParts.contains(where: { $0.isEmpty }) {
      return .patternInvalid("Remove the empty entry between commas.")
    }

    for part in rawParts {
      if let bad = part.first(where: { forbidden.contains($0) }) {
        let shown = bad == " " ? "spaces" : "\"\(bad)\""
        return .patternInvalid("Index patterns can't contain \(shown).")
      }
      if part.hasPrefix("-") {
        return .patternInvalid("Exclusions (patterns starting with -) aren't supported yet.")
      }
    }
    return nil
  }

  /// Whether an index name matches any part of the pattern
  public static func matches(pattern: String, index: String) -> Bool {
    return parts(of: pattern).contains { part in
      guard let regex = regex(for: part) else { return false }
      let range = NSRange(index.startIndex..., in: index)
      return regex.firstMatch(in: index, range: range) != nil
    }
  }

  static func regex(for part: String) -> NSRegularExpression? {
    let body = NSRegularExpression.escapedPattern(for: part)
      .replacingOccurrences(of: "\\*", with: ".*")
    return try? NSRegularExpression(pattern: "^\(body)$")
  }

  /// One entry per field path, sorted by path. A pattern's mapping lists each field once per index;
  /// when the indexes disagree on its type, the types are joined, eg. "keyword, text".
  public static func mergeFields(_ fields: [SquashedFieldsArray]) -> [SquashedFieldsArray] {
    var firstSeen: [String: SquashedFieldsArray] = [:]
    var types: [String: [String]] = [:]
    for field in fields {
      let path = field.squashedString
      if firstSeen[path] == nil {
        firstSeen[path] = field
        types[path] = []
      }
      if !field.type.isEmpty && !(types[path]?.contains(field.type) ?? false) {
        types[path]?.append(field.type)
      }
    }
    return firstSeen.keys
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
      .compactMap { path in
        guard let source = firstSeen[path] else { return nil }
        let merged = SquashedFieldsArray(squashedString: path, fieldParts: source.fieldParts)
        merged.type = (types[path] ?? []).sorted().joined(separator: ", ")
        return merged
      }
  }

  /// Index names for a list: hidden indexes (a leading ".") after the rest, each group case-insensitively
  public static func sortedIndexNames<S: Sequence>(_ names: S) -> [String] where S.Element == String {
    return names.sorted { a, b in
      let aHidden = a.hasPrefix(".")
      let bHidden = b.hasPrefix(".")
      if aHidden != bHidden {
        return !aHidden
      }
      return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
    }
  }

  /// A pattern for an index's whole series: strips a trailing date or number suffix,
  /// eg. "backtesting-experiments-2026-36" → "backtesting-experiments-*", "logs-2026.10.06" → "logs-*".
  /// Returns the name unchanged when there's no suffix to strip.
  public static func suggest(from index: String) -> String {
    let trimmed = index.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let regex = try? NSRegularExpression(pattern: "^(.*?[^-_.][-_.])\\d+(?:[-_.]\\d+)*$") else {
      return trimmed
    }
    let range = NSRange(trimmed.startIndex..., in: trimmed)
    guard let match = regex.firstMatch(in: trimmed, range: range),
          let prefix = Range(match.range(at: 1), in: trimmed) else {
      return trimmed
    }
    return String(trimmed[prefix]) + "*"
  }
}
