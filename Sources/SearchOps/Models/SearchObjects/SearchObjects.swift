// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public struct FieldsArray : Hashable {
  public let id : UUID = UUID()
  public let name : String
  public let type : FieldType = .object
  public var values : [FieldsArray]?
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
  public static func == (lhs: FieldsArray, rhs: FieldsArray) -> Bool {
    return lhs.name == rhs.name
  }
}

@available(macOS 10.15, *)
@available(iOS 15.0, *)
public class SquashedFieldsArray : Identifiable, Hashable, ObservableObject {
    
    public init(id: UUID = UUID(), squashedString: String = "", fieldParts : [String] = [String]()) {
        self.id = id
        self.squashedString = squashedString
      self.fieldParts = fieldParts
    }
    
    public var id : UUID
    public var squashedString : String
    public var fieldParts : [String] = [String]()
    public var type : String = ""
    public var index : String = ""
    
    @Published
    public var visible : Bool =  false
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: SquashedFieldsArray, rhs: SquashedFieldsArray) -> Bool {
       return lhs.id == rhs.id
   }
}



@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class IndexResult : ObservableObject {
		public var data : [String] = []
		public var error : String?
}

