// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public enum SearchDateTimePeriods: String, CaseIterable, PersistableEnum {
    case Seconds
    case Minutes
    case Hours
    case Days
    case Weeks
    case Months
    case Years
}

public enum SortOrderEnum: String, PersistableEnum {
	case Ascending = "asc"
	case Descending = "desc"
}

@available(macOS 10.15, *)
@available(iOS 15.0, *)
public class SortObject : ObservableObject {
	
	public init(order: SortOrderEnum, field: SquasedFieldsArray) {
		self.order = order
		self.field = field
	}

	@Published public var order: SortOrderEnum
	@Published public var field: SquasedFieldsArray
}

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class FilterObject: ObservableObject {
	
	public init(id: UUID = UUID(),
							query: QueryObject? = nil,
							dateField: SquasedFieldsArray? = nil,
							relativeRange: RelativeRangeFilter? = nil,
							absoluteRange: AbsoluteDateRangeObject? = nil,
							sort: SortObject? = nil) {
		self.query = query
		self.dateField = dateField
		self.relativeRange = relativeRange
		self.absoluteRange = absoluteRange
		self.sort = sort
	}
	
	@Published public var id: UUID = UUID()
	@Published public var query: QueryObject? = nil {
		didSet {
			id = UUID()
		}
	}
	@Published public var dateField: SquasedFieldsArray? = nil  {
		didSet {
			id = UUID()
		}
	}
	
	@Published public var sort: SortObject? = nil  {
		didSet {
			id = UUID()
		}
	}
	
	@Published public var relativeRange: RelativeRangeFilter? = nil
	{
		didSet {
			id = UUID()
		}
	}
	@Published public var absoluteRange: AbsoluteDateRangeObject? = nil
	{
		didSet {
			id = UUID()
		}
	}
	
}

@available(macOS 13.0, *)
@available(iOS 15, *)
public class RealmFilterObject: Object {
    
    @Persisted(primaryKey: true) public var id: UUID = UUID()
    @Persisted public var query: QueryObject? = nil
    @Persisted public var dateField: RealmSquasedFieldsArray?
    @Persisted public var relativeRange: RealmRelativeRangeFilter?
    @Persisted public var absoluteRange: RealmAbsoluteDateRangeObject?
    @Persisted public var date: Date = Date.now
    @Persisted public var count: Int = 1
    
}

@available(macOS 10.15, *)
@available(iOS 15, *)
public class RealmSquasedFieldsArray : EmbeddedObject {
    
    public convenience init(squasedField: SquasedFieldsArray) {
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
    
}

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class RelativeRangeFilter : ObservableObject {
    
    public init(period: SearchDateTimePeriods = SearchDateTimePeriods.Minutes, value: Double = 0.0) {
        self.period = period
        self.value = value
    }
    
    
    @Published public var period: SearchDateTimePeriods = SearchDateTimePeriods.Minutes
    @Published public var value: Double = 0.0
    
    public func GetFromTime() -> Date {
      let seconds = DateTools.calculateSecondsByPeriod(value: self.value, period: self.period)
      return Date.now - seconds
    }
    
    public func ejectRealmObject() -> RealmRelativeRangeFilter {
        let realmObj = RealmRelativeRangeFilter()
        realmObj.period = self.period
        realmObj.value = self.value
        return realmObj
    }
}

public class RealmRelativeRangeFilter : EmbeddedObject {
    
//    @Persisted var active: Bool = false
    @Persisted public var period: SearchDateTimePeriods = SearchDateTimePeriods.Minutes
    @Persisted public var value: Double = 0.0
    
}

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class AbsoluteDateRangeObject : ObservableObject {
    public init(from: Date = Date.now, to: Date = Date.now) {
        self.from = from
        self.to = to
    }
    
    
    @Published public var from: Date = Date.now
    @Published public var to: Date = Date.now
    
    public func ejectRealmObject() -> RealmAbsoluteDateRangeObject {
        let realmObj = RealmAbsoluteDateRangeObject()
        realmObj.from = self.from
        realmObj.to = self.to
        return realmObj
    }

}

@available(macOS 13.0, *)
@available(iOS 15, *)
public class RealmAbsoluteDateRangeObject : EmbeddedObject {
    
    @Persisted public var active: Bool = false
    @Persisted public var from: Date = Date.now
    @Persisted public var to: Date = Date.now

}

public enum QueryCompoundEnum: String, PersistableEnum {
	case must = "AND"
	case should = "OR"
}

public class QueryObject : EmbeddedObject {
	
	public func eject() -> QueryObject {
		var detachedObject = QueryObject()
		
		// Build up the list object
		detachedObject.values = List<QueryFilterObject>()
		for item in values {
			detachedObject.values.append(QueryFilterObject(string:item.string))
		}
		
		// Creating enum's to avoid any references to the existing object
		if self.compound == .must {
			detachedObject.compound = .must
		} else {
			detachedObject.compound = .should
		}
		
		return detachedObject
	}

	@Persisted public var values: List<QueryFilterObject> = List<QueryFilterObject>()
	@Persisted public var compound: QueryCompoundEnum
}


public class QueryFilterObject : EmbeddedObject {
    
    public convenience init(string: String = "*") {
        self.init()
        self.string = string
    }
    
    @Persisted public var string: String = "*"
}

