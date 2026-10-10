// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// The word being typed in a query, which a suggestion replaces
public struct QueryAutocompleteToken: Equatable {
  /// UTF-16 range in the query: for a field name, from after any -, + or ! to the end of the word;
  /// for a value, everything after the colon, including any quotes
  public var range: NSRange
  /// What's typed from the start of the range up to the cursor
  public var prefix: String

  public init(range: NSRange, prefix: String) {
    self.range = range
    self.prefix = prefix
  }
}

/// What's being typed at the cursor: a field name, or a value after `field:`
public enum QueryAutocompleteContext: Equatable {
  case field(QueryAutocompleteToken)
  case value(field: String, token: QueryAutocompleteToken)
}

public struct QueryAutocompleteSuggestion: Equatable, Identifiable {
  public enum Kind: Equatable {
    case field, value
  }

  /// A field name, or a value as the server returned it
  public var text: String
  public var kind: Kind
  /// The field's type, empty for values
  public var type: String
  /// The data view's label for the field, when it has one
  public var label: String?

  public var id: String { text }

  public init(text: String, kind: Kind = .field, type: String = "", label: String? = nil) {
    self.text = text
    self.kind = kind
    self.type = type
    self.label = label
  }
}

/// Field name and value completion for the `query_string` search box. Offsets are UTF-16,
/// as NSText's selectedRange uses.
public enum QueryAutocomplete {

  public static let maxSuggestions = 50

  static let operators: Set<String> = ["AND", "OR", "NOT", "&&", "||"]
  static let modifiers: Set<Character> = ["-", "+", "!"]
  static let boundaries: Set<Character> = ["(", ")", "[", "]", "{", "}"]
  /// Characters query_string won't take unescaped in a field name.
  /// - and + only matter at the start, so they're handled separately.
  static let reserved: Set<Character> = ["\\", "\"", "(", ")", "[", "]", "{", "}", "^", "~",
                                         "*", "?", ":", "/", "!", "<", ">", "=", "&", "|", " "]

  /// The word at the cursor when it could be a field name, nil inside quotes, after a colon,
  /// for an operator, or when nothing has been typed yet
  public static func token(in text: String, cursor: Int) -> QueryAutocompleteToken? {
    let ns = text as NSString
    guard cursor >= 0, cursor <= ns.length else { return nil }

    if isInsideQuotes(ns, before: cursor) {
      return nil
    }

    var start = cursor
    while start > 0, !isBoundary(ns, at: start - 1) {
      start -= 1
    }
    var end = cursor
    while end < ns.length, !isBoundary(ns, at: end) {
      end += 1
    }

    let word = ns.substring(with: NSRange(location: start, length: end - start))
    if word.contains(":") || operators.contains(word) {
      return nil
    }

    while start < cursor, let character = character(ns, at: start), modifiers.contains(character) {
      start += 1
    }

    let prefix = ns.substring(with: NSRange(location: start, length: cursor - start))
    if prefix.isEmpty {
      return nil
    }
    return QueryAutocompleteToken(range: NSRange(location: start, length: end - start), prefix: prefix)
  }

  /// Field names matching the typed text: names starting with it first, then names with a
  /// dotted part or label starting with it, then names or labels containing it
  public static func suggestions(for prefix: String,
                                 fields: [SquashedFieldsArray],
                                 labels: [String: String] = [:]) -> [QueryAutocompleteSuggestion] {
    let needle = prefix.lowercased()
    if needle.isEmpty {
      return []
    }

    var seen = Set<String>()
    var ranked = [(rank: Int, suggestion: QueryAutocompleteSuggestion)]()

    for field in fields {
      let name = field.squashedString
      if name.isEmpty || seen.contains(name) || field.type == "object" || field.type == "nested" {
        continue
      }
      seen.insert(name)

      let lowerName = name.lowercased()
      if lowerName == needle {
        continue
      }
      let label = labels[name].flatMap { $0.isEmpty ? nil : $0 }
      let lowerLabel = label?.lowercased()

      let rank: Int
      if lowerName.hasPrefix(needle) {
        rank = 0
      } else if lowerName.split(separator: ".").dropFirst().contains(where: { $0.hasPrefix(needle) })
                  || lowerLabel?.hasPrefix(needle) == true {
        rank = 1
      } else if lowerName.contains(needle) || lowerLabel?.contains(needle) == true {
        rank = 2
      } else {
        continue
      }
      ranked.append((rank, QueryAutocompleteSuggestion(text: name, type: field.type, label: label)))
    }

    return ranked
      .sorted {
        if $0.rank != $1.rank {
          return $0.rank < $1.rank
        }
        return $0.suggestion.text.localizedCaseInsensitiveCompare($1.suggestion.text) == .orderedAscending
      }
      .prefix(maxSuggestions)
      .map(\.suggestion)
  }

  /// Replaces the token with `field:`, leaving the cursor after the colon
  public static func apply(field: String,
                           to text: String,
                           token: QueryAutocompleteToken) -> (text: String, cursor: Int) {
    let replacement = escapeField(field) + ":"
    let updated = (text as NSString).replacingCharacters(in: token.range, with: replacement)
    return (updated, token.range.location + (replacement as NSString).length)
  }

  /// A field name or value at the cursor, nil when neither can be suggested
  public static func context(in text: String, cursor: Int) -> QueryAutocompleteContext? {
    if let token = token(in: text, cursor: cursor) {
      return .field(token)
    }
    return valueToken(in: text, cursor: cursor).map { .value(field: $0.field, token: $0.token) }
  }

  /// The value being typed after `field:`, which may be empty or an unfinished quoted phrase.
  /// Nil with the cursor in the field name, after a finished phrase, or in a range such as [1 TO 5]
  public static func valueToken(in text: String, cursor: Int) -> (field: String, token: QueryAutocompleteToken)? {
    let ns = text as NSString
    guard cursor >= 0, cursor <= ns.length else { return nil }

    // The value starts after the colon: at an opening quote when inside one, or the word's start
    let colon: Int
    let end: Int
    if isInsideQuotes(ns, before: cursor) {
      var quote = cursor - 1
      while quote >= 0, !(character(ns, at: quote) == "\"" && !isEscaped(ns, at: quote)) {
        quote -= 1
      }
      guard quote > 0, character(ns, at: quote - 1) == ":" else { return nil }
      colon = quote - 1
      var closing = cursor
      while closing < ns.length, !(character(ns, at: closing) == "\"" && !isEscaped(ns, at: closing)) {
        closing += 1
      }
      end = min(closing + 1, ns.length)
    } else {
      var start = cursor
      while start > 0, !isBoundary(ns, at: start - 1) {
        start -= 1
      }
      var wordEnd = cursor
      while wordEnd < ns.length, !isBoundary(ns, at: wordEnd) {
        wordEnd += 1
      }
      guard let found = firstColon(ns, from: start, to: cursor) else { return nil }
      // A value that starts with a quote here is a finished phrase
      if found + 1 < ns.length, character(ns, at: found + 1) == "\"" {
        return nil
      }
      colon = found
      end = wordEnd
    }

    // The field name runs back from the colon to a boundary, less any -, + or !
    var fieldStart = colon
    while fieldStart > 0, !isBoundary(ns, at: fieldStart - 1) {
      fieldStart -= 1
    }
    while fieldStart < colon, let character = character(ns, at: fieldStart), modifiers.contains(character) {
      fieldStart += 1
    }
    let field = ns.substring(with: NSRange(location: fieldStart, length: colon - fieldStart))
      .replacingOccurrences(of: "\\", with: "")
    if field.isEmpty || field.contains(":") || field == "_exists_" {
      return nil
    }

    var prefix = ns.substring(with: NSRange(location: colon + 1, length: cursor - colon - 1))
    if prefix.hasPrefix("\"") {
      prefix.removeFirst()
    }
    return (field, QueryAutocompleteToken(range: NSRange(location: colon + 1, length: end - colon - 1),
                                          prefix: prefix))
  }

  /// Values matching what's typed of the value: those starting with it, then those containing it,
  /// each in the order given (most recent first). An empty prefix keeps them all.
  public static func valueSuggestions(for prefix: String, values: [String]) -> [QueryAutocompleteSuggestion] {
    let needle = prefix.lowercased()
    var seen = Set<String>()
    var starts = [QueryAutocompleteSuggestion]()
    var contains = [QueryAutocompleteSuggestion]()
    for value in values where !value.isEmpty && seen.insert(value).inserted {
      let lower = value.lowercased()
      if !needle.isEmpty && lower == needle {
        continue
      }
      if lower.hasPrefix(needle) {
        starts.append(QueryAutocompleteSuggestion(text: value, kind: .value))
      } else if lower.contains(needle) {
        contains.append(QueryAutocompleteSuggestion(text: value, kind: .value))
      }
    }
    return starts + contains
  }

  /// Replaces the value with the chosen one, quoted when it needs to be, followed by a space
  /// unless one is already there. The cursor goes after the space.
  public static func apply(value: String,
                           to text: String,
                           token: QueryAutocompleteToken) -> (text: String, cursor: Int) {
    let ns = text as NSString
    let after = token.range.location + token.range.length
    let spaceFollows = after < ns.length && (character(ns, at: after)?.isWhitespace ?? false)
    let replacement = formatValue(value) + (spaceFollows ? "" : " ")
    let updated = ns.replacingCharacters(in: token.range, with: replacement)
    let cursor = token.range.location + (replacement as NSString).length + (spaceFollows ? 1 : 0)
    return (updated, cursor)
  }

  /// A value as query_string reads it: plain when it's only letters, digits, `.`, `_` and `@`,
  /// otherwise in quotes, eg. "eu west" or "web-1"
  public static func formatValue(_ value: String) -> String {
    let plain = !value.isEmpty
      && !operators.contains(value)
      && value.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) || "._@".unicodeScalars.contains($0) }
    if plain {
      return value
    }
    let escaped = value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"" + escaped + "\""
  }

  /// Backslash-escapes the characters query_string reads as syntax
  public static func escapeField(_ field: String) -> String {
    var escaped = ""
    for (offset, character) in field.enumerated() {
      if reserved.contains(character) || (offset == 0 && (character == "-" || character == "+")) {
        escaped.append("\\")
      }
      escaped.append(character)
    }
    return escaped
  }

  static func character(_ ns: NSString, at index: Int) -> Character? {
    guard let scalar = Unicode.Scalar(ns.character(at: index)) else { return nil }
    return Character(scalar)
  }

  static func isBoundary(_ ns: NSString, at index: Int) -> Bool {
    // Surrogate halves (emoji) aren't scalars and are never boundaries
    guard let character = character(ns, at: index) else { return false }
    return character.isWhitespace || boundaries.contains(character)
  }

  /// Whether the character at index follows an odd number of backslashes
  static func isEscaped(_ ns: NSString, at index: Int) -> Bool {
    var backslashes = 0
    var position = index - 1
    while position >= 0, character(ns, at: position) == "\\" {
      backslashes += 1
      position -= 1
    }
    return backslashes % 2 == 1
  }

  /// The first unescaped colon in start..<end
  static func firstColon(_ ns: NSString, from start: Int, to end: Int) -> Int? {
    var index = start
    while index < end {
      if character(ns, at: index) == ":", !isEscaped(ns, at: index) {
        return index
      }
      index += 1
    }
    return nil
  }

  /// An odd number of unescaped quotes before the cursor
  static func isInsideQuotes(_ ns: NSString, before cursor: Int) -> Bool {
    var inside = false
    var escaped = false
    for index in 0..<cursor {
      let character = character(ns, at: index)
      if escaped {
        escaped = false
      } else if character == "\\" {
        escaped = true
      } else if character == "\"" {
        inside.toggle()
      }
    }
    return inside
  }
}
