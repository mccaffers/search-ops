//
//  DateSheetListView.swift
//  PocketSearch
//
//  Created by Ryan McCaffery on 14/06/2023.
//

import SwiftUI


struct DateSheetListView: View {
	
	var fields : [SquashedFieldsArray]
	@Binding var localField : SquashedFieldsArray?
	
	@Environment(\.dismiss) private var dismiss
	var selectedIndex : String? = nil
	@EnvironmentObject var filterObject : FilterObject
	
	@State var showAllObjects = false
	@State var usingLocalField = false
	
	
	func filter() -> [SquashedFieldsArray] {
		var filter = fields
			.filter({$0.type == "date"})
			.sorted {$0.squashedString < $1.squashedString}
		
		if showAllObjects {
			filter = fields
				.sorted {$0.squashedString < $1.squashedString}
		}
		
		return filter
		
	}
	var title = "Date Fields"
	var body: some View {
		VStack {
			
			
			
			if fields.count > 0 {
              
              
              // TODO Fix this
//              if let index = selectedIndex {
//                Text("Found " +
//                     fields.filter({$0.type == "date"}).count.string +
//                     " field(s) in " + index + " with the date type")
//                .multilineTextAlignment(.leading)
//                .frame(maxWidth: .infinity, alignment:.leading)
//                .padding(.horizontal, 15)
//              }
              
				
				List {
					
					ForEach(filter(),
									id: \.self) { item in
						
						VStack {
							Button {
								// either save to a loca object
								// or change the filtered object
								if usingLocalField {
									localField = item
								} else {
									if let dateObj = filterObject.dateField,
										 dateObj.index == item.index,
										 dateObj.squashedString == item.squashedString {
										filterObject.dateField = nil
									} else {
										filterObject.dateField = item
									}
								}
								
								dismiss()
								
							} label: {
								
								if usingLocalField {
									DateSheetListButtonLabel(activeField: filterObject.sort?.field,
																					 item: item,
																					 selectedIndex: selectedIndex,
																					 fieldCount: fields.count)
								} else {
									DateSheetListButtonLabel(activeField: filterObject.dateField,
																					 item: item,
																					 selectedIndex: selectedIndex,
																					 fieldCount: fields.count)
								}
								
								
							
								
								
								
							}
						}
						.listRowInsets(EdgeInsets())
						.listRowSeparator(.hidden, edges: [.bottom])
						.listRowBackground(Color.clear)
						.padding(.bottom, 10)
					}
					
					
					
					
				}.listStyle(.plain)
			}
			
			
		}
		.navigationTitle(title)
#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
      #endif
		.padding(.top, 10)
		.background(Color("Background"))
		.frame(maxWidth: .infinity)
	}
}
