// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
public class HostUpdatedNotifier : ObservableObject {
  
  public init(){}
  
  @Published
  public var updated : UUID = UUID()
  
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
  
  public var debugDescription: String {
    return "SquashedFieldsArray(id: \(id), squashedString: \(squashedString), fieldParts: \(fieldParts), type: \(type), index: \(index), visible: \(visible))"
  }
}



@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class IndexResult : ObservableObject {
		public var data : [String] = []
		public var hiddenData : [String] = []
		public var error : String?
}

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public struct IndexStatsItem: Equatable, Sendable {
  public var docCount: Int?
  public var storageBytes: Int64?
  public var totalDocCount: Int?
  public var totalStorageBytes: Int64?
  public var deletedDocCount: Int?

  public init(
    docCount: Int? = nil,
    storageBytes: Int64? = nil,
    totalDocCount: Int? = nil,
    totalStorageBytes: Int64? = nil,
    deletedDocCount: Int? = nil
  ) {
    self.docCount = docCount
    self.storageBytes = storageBytes
    self.totalDocCount = totalDocCount
    self.totalStorageBytes = totalStorageBytes
    self.deletedDocCount = deletedDocCount
  }

  public var formattedDocCount: String? {
    guard let count = docCount, count >= 0 else { return nil }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    let formattedNumber = formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    return count == 1 ? "\(formattedNumber) doc" : "\(formattedNumber) docs"
  }

  public var formattedStorageSize: String? {
    guard let bytes = storageBytes, bytes >= 0 else { return nil }
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]
    formatter.countStyle = .file
    formatter.allowsNonnumericFormatting = false
    return formatter.string(fromByteCount: bytes)
  }
}

