// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public struct FieldsArray : Hashable {
    public let id : UUID = UUID()
    public let name : String
    public var values : [FieldsArray]?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    public static func == (lhs: FieldsArray, rhs: FieldsArray) -> Bool {
        return lhs.name == rhs.name
    }
}

@available(macOS 10.15, *)
@available(macOS 10.15, *)
@available(iOS 15.0, *)
public class SquasedFieldsArray : Identifiable, Hashable, ObservableObject {
    
    public init(id: UUID = UUID(), squashedString: String = "") {
        self.id = id
        self.squashedString = squashedString
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
    
    public static func == (lhs: SquasedFieldsArray, rhs: SquasedFieldsArray) -> Bool {
       return lhs.id == rhs.id
   }
}

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class SearchResult : ObservableObject {
    
    public init(data: [[String : Any]] = [], error: String? = nil) {
        self.data = data
        self.error = error
    }
    
    public var data : [[String : Any]] = []
    public var error : String?
}

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class IndexResult : ObservableObject {
		public var data : [String] = []
		public var error : String?
}


@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class RenderResult : ObservableObject {
    public var results : [[String : Any]] = []
    public var error : ResponseError?
    public var pages : Int = 0
    public var hits : Int = 0
    public var fields : [SquasedFieldsArray]? = nil
    public var mapping : [SquasedFieldsArray]? = nil
}
