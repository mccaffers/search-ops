// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 10.15, *)
@available(iOS 15.0, *)
public class SortObject : ObservableObject {
	
	public init(order: SortOrderEnum, field: SquashedFieldsArray) {
		self.order = order
		self.field = field
	}

	@Published public var order: SortOrderEnum
	@Published public var field: SquashedFieldsArray
}



