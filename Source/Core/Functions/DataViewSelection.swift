// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// Starts a search: the host, the index (a data view's pattern when one is chosen), the filters,
/// and the data view the search was started from, if any
public typealias SearchRequestAction = (_ selectedHost: HostDetails,
                                        _ selectedIndex: String,
                                        _ filterObject: FilterObject,
                                        _ dataView: DataView?) -> ()

/// A data view chosen on the Search tab. Searches still run against the index string, which is the
/// view's pattern; the view only changes what's shown (its name, time field and labels).
public enum DataViewSelection {

  /// The indexes in the list that the pattern includes, in list order
  public static func matchingIndices(for pattern: String, in indexes: [String]) -> [String] {
    indexes.filter { DataViewPattern.matches(pattern: pattern, index: $0) }
  }

  /// The view stays chosen only while the index is still its pattern, eg. picking a single index clears it
  public static func keep(_ view: DataView?, forIndex index: String) -> DataView? {
    guard let view = view, view.normalized().pattern == index else { return nil }
    return view
  }

  /// The view a recent search was made with: the only view on the host with that pattern.
  /// nil when none has it, or when more than one does and there's no telling which.
  public static func view(forHistoryIndex index: String, in views: [DataView]) -> DataView? {
    let matches = views.filter { $0.normalized().pattern == index }
    return matches.count == 1 ? matches[0] : nil
  }

  /// The view's time field as a date field to search and sort by, or nil when it has none
  public static func timeField(of view: DataView) -> SquashedFieldsArray? {
    let path = view.normalized().timeField
    guard !path.isEmpty else { return nil }
    let field = SquashedFieldsArray(squashedString: path, fieldParts: path.components(separatedBy: "."))
    field.type = "date"
    return field
  }

  /// The field's label in the view, or nil when it has none
  public static func label(for path: String, labels: [String: String]) -> String? {
    guard let label = labels[path]?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty else {
      return nil
    }
    return label
  }
}
