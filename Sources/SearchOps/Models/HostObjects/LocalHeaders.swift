// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class LocalHeaders : ObservableObject, Identifiable, Equatable  {
    
    public static func == (lhs: LocalHeaders, rhs: LocalHeaders) -> Bool {
        return lhs.id == rhs.id
    }
    
    public init(id: UUID = UUID(), header: String = "", value: String = "", focusedIndexHeader: Double = 0, focusedIndexValue: Double = 0) {
        self.id = id
        self.header = header
        self.value = value
        self.focusedIndexHeader = focusedIndexHeader
        self.focusedIndexValue = focusedIndexValue
    }
    

    @Published public var id: UUID = UUID()
    @Published public var header: String = ""
    @Published public var value: String = ""
    @Published public var focusedIndexHeader: Double = 0
    @Published public var focusedIndexValue: Double = 0
}
