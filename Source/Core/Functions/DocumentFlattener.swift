// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import OrderedCollections

/// A field found in search results: its dotted name, and the keys in the document that lead to it.
public struct FlatField: Hashable, Sendable {
  public let key: String
  public let parts: [String]
}

/// Documents flattened into rows of dotted field names and their values, with every field found in them.
public struct FlatPage {
  /// One row per document, holding the `[String]` values of each field it has, sorted by field name.
  public let rows: [OrderedDictionary<String, Any>]
  /// Every field with a value in at least one document, sorted by name.
  public let fields: [FlatField]
}

/// Flattens search result documents, walking each one once. Objects become dotted field names, every element
/// of an array is a value of the same field, and values become text. `null`, `{}` and `[]` hold no value,
/// so a field that's only ever one of those isn't listed.
public enum DocumentFlattener {

  public static func flattenPage(_ documents: [[String: Any]]) -> FlatPage {
    var parts = [String: [String]]()
    var path = [String]()

    let rows = documents.map { document -> OrderedDictionary<String, Any> in
      var values = [String: [String]]()
      flatten(document, key: "", path: &path, values: &values, parts: &parts)

      var row = OrderedDictionary<String, Any>(minimumCapacity: values.count)
      for (key, fieldValues) in values.sorted(by: { $0.key < $1.key }) {
        row[key] = fieldValues
      }
      return row
    }

    let fields = parts.sorted { $0.key < $1.key }.map { FlatField(key: $0.key, parts: $0.value) }
    return FlatPage(rows: rows, fields: fields)
  }

  /// Adds the values under `value` to `values`, and the keys that lead to each field to `parts`.
  /// `path` holds the keys from the document down to `value`.
  static func flatten(_ value: Any,
                      key: String,
                      path: inout [String],
                      values: inout [String: [String]],
                      parts: inout [String: [String]]) {
    if let object = value as? [String: Any] {
      for (name, child) in object {
        path.append(name)
        flatten(child, key: path.count == 1 ? name : key + "." + name, path: &path, values: &values, parts: &parts)
        path.removeLast()
      }
    } else if let array = value as? [Any] {
      for element in array {
        flatten(element, key: key, path: &path, values: &values, parts: &parts)
      }
    } else if let text = text(for: value) {
      values[key, default: []].append(text)
      if let known = parts[key] {
        if prefers(path, over: known) {
          parts[key] = path
        }
      } else {
        parts[key] = path
      }
    }
  }

  /// Picks the keys for a field reached in more than one way, eg. `"host.name"` and `"host": {"name"}`.
  /// The most deeply nested way wins, then the first in alphabetical order, so the choice doesn't depend on
  /// the order the keys come in.
  static func prefers(_ candidate: [String], over current: [String]) -> Bool {
    if candidate.count != current.count {
      return candidate.count > current.count
    }
    return candidate.lexicographicallyPrecedes(current)
  }

  /// The text shown for a JSON value: strings as they are, booleans as true or false, and numbers as before,
  /// with whole numbers written without a decimal point. Nil for anything else, such as null.
  public static func text(for value: Any) -> String? {
    if let string = value as? String {
      return string
    }
    if let boolean = booleanText(value) {
      return boolean
    }
    if let whole = value as? Int {
      return String(whole)
    }
    if let decimal = value as? Double {
      return String(decimal)
    }
    return nil
  }

  /// "true" or "false" for a JSON boolean, which would otherwise read as the number 1 or 0. Nil for anything else.
  public static func booleanText(_ value: Any?) -> String? {
    guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else {
      return nil
    }
    return number.boolValue ? "true" : "false"
  }

  /// The texts of an array that holds only booleans, or nil.
  public static func booleanTexts(_ value: Any?) -> [String]? {
    guard let array = value as? [Any], !array.isEmpty else {
      return nil
    }
    let texts = array.compactMap { booleanText($0) }
    return texts.count == array.count ? texts : nil
  }
}
