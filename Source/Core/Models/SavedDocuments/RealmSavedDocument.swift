// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// A saved document reference for one host.
/// New columns must be optional or default to a valid empty value, and not be enums:
/// rows that already exist start with the column empty, so no migration code is needed.
public class RealmSavedDocument: Object {

  @Persisted(primaryKey: true) public var id: UUID
  @Persisted(indexed: true) public var hostId: UUID
  @Persisted public var docIndex: String = ""
  @Persisted public var docId: String = ""
  @Persisted public var title: String = ""
  @Persisted public var searchIndex: String = ""
  @Persisted public var dataViewId: UUID?
  // "" means no date field
  @Persisted public var dateField: String = ""
  @Persisted public var dateFieldParts: List<String>
  @Persisted public var dateFieldType: String = ""
  // Both set, or neither
  @Persisted public var rangeFrom: Date?
  @Persisted public var rangeTo: Date?
  @Persisted public var savedDate: Date = Date.now

  public convenience init(document: SavedDocument) {
    self.init()
    self.id = document.id
    self.hostId = document.hostId
    self.docIndex = document.docIndex
    self.docId = document.docId
    self.title = document.title
    self.searchIndex = document.searchIndex
    self.dataViewId = document.dataViewId
    if let field = document.dateField {
      self.dateField = field.field
      self.dateFieldParts.append(objectsIn: field.parts)
      self.dateFieldType = field.type
    }
    self.rangeFrom = document.timeRange?.start
    self.rangeTo = document.timeRange?.end
    self.savedDate = document.savedDate
  }

  /// A plain copy that's safe to keep after the object is deleted
  public func eject() -> SavedDocument {
    var range: DateInterval? = nil
    if let from = rangeFrom, let to = rangeTo, from <= to {
      range = DateInterval(start: from, end: to)
    }
    return SavedDocument(id: id,
                         hostId: hostId,
                         docIndex: docIndex,
                         docId: docId,
                         title: title,
                         searchIndex: searchIndex,
                         dataViewId: dataViewId,
                         dateField: dateField.isEmpty ? nil : SavedDateField(field: dateField,
                                                                             parts: Array(dateFieldParts),
                                                                             type: dateFieldType),
                         timeRange: range,
                         savedDate: savedDate)
  }
}
