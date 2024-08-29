// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13, *)
@available(iOS 15.0, *)
public class RealmSquashedFieldsArray : EmbeddedObject {
  
  public convenience init(squasedField: SquashedFieldsArray) {
    self.init()
    
    self.id = squasedField.id
    self.squashedString = squasedField.squashedString
    
    let myList = List<String>()
    myList.append(objectsIn: squasedField.fieldParts)
    self.fieldParts = myList
    self.type = squasedField.type
    self.index = squasedField.index
  }
  
  
  @Persisted public var id: UUID = UUID()
  @Persisted public var squashedString : String = ""
  @Persisted public var fieldParts : List<String> = List<String>()
  @Persisted public var type : String = ""
  @Persisted public var index : String = ""
  
  public func eject() -> SquashedFieldsArray {
    var fieldArray = SquashedFieldsArray()
    fieldArray.squashedString = self.squashedString
    fieldArray.fieldParts = self.fieldParts.sorted()
    fieldArray.type = self.type
    fieldArray.index = self.index
    return fieldArray
  }
  
  public func copy() -> RealmSquashedFieldsArray {
    let dateField = RealmSquashedFieldsArray()
    dateField.fieldParts = self.fieldParts
    dateField.squashedString = self.squashedString
    dateField.type = self.type
    dateField.index = self.index
    return dateField
  }
  
  public func isEqual(object: RealmSquashedFieldsArray?) -> Bool {
    guard self.squashedString == object?.squashedString else { return false }
    guard self.fieldParts.count == object?.fieldParts.count else { return false }
    guard self.type == object?.type else { return false }
    return true
  }
  
}
