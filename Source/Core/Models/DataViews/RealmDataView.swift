// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// A saved index pattern for one host, with optional labels for its fields.
/// New columns must be optional or default to a valid empty value, and not be enums:
/// rows that already exist start with the column empty, so no migration code is needed.
public class RealmDataView: Object {

  @Persisted(primaryKey: true) public var id: UUID
  @Persisted(indexed: true) public var hostId: UUID
  @Persisted public var name: String = ""
  @Persisted public var pattern: String = ""
  // "" means no default time field
  @Persisted public var timeField: String = ""
  // Embedded, so deleting the view deletes its labels
  @Persisted public var fieldLabels: List<RealmFieldLabel>
  @Persisted public var createdDate: Date = Date.now
  @Persisted public var updatedDate: Date = Date.now

  public convenience init(view: DataView) {
    self.init()
    self.id = view.id
    self.hostId = view.hostId
    self.createdDate = view.createdDate
    apply(view)
  }

  /// Copies everything a user can edit. The id, host and created date stay as they are.
  public func apply(_ view: DataView) {
    name = view.name
    pattern = view.pattern
    timeField = view.timeField
    updatedDate = view.updatedDate

    fieldLabels.removeAll()
    for field in view.labels.keys.sorted() {
      guard let label = view.labels[field] else { continue }
      let item = RealmFieldLabel()
      item.field = field
      item.label = label
      fieldLabels.append(item)
    }
  }

  /// A plain copy that's safe to keep after the object is deleted
  public func eject() -> DataView {
    var labels: [String: String] = [:]
    for item in fieldLabels {
      labels[item.field] = item.label
    }
    return DataView(id: id,
                    hostId: hostId,
                    name: name,
                    pattern: pattern,
                    timeField: timeField,
                    labels: labels,
                    createdDate: createdDate,
                    updatedDate: updatedDate)
  }
}

public class RealmFieldLabel: EmbeddedObject {
  @Persisted public var field: String = ""
  @Persisted public var label: String = ""
}
