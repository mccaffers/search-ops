//
//  SearchQueryDatePopup.swift
//  SearchOpsApp
//
//  Created by Ryan McCaffery on 18/07/2023.
//

import SwiftUI



enum DateField : String, CaseIterable {
	 case To
	 case From
 }

struct SearchQueryDatePopup: View {
	
	@EnvironmentObject var filterObject: FilterObject
	
	@Binding var showDateInputView : DateQuery?
	@State var offset = CGFloat(1)
	
	@State var selected : DateField = .From

	@State var fromDate : Date = Date.now
	@State var toDate : Date = Date.now
	
	@State var showingDateList = false
	
	var fields : [SquashedFieldsArray]
	
	@State var localField : SquashedFieldsArray? = nil
	
	var body: some View {
		
		ScrollView {
			
			if let dateObj = showDateInputView {
				
				VStack(spacing:10) {
					
					VStack(spacing:5){
						Text("Query Date")
							.foregroundColor(Color("TextSecondary"))
							.font(.system(size:14))
							.frame(maxWidth: .infinity, alignment:.leading)
						
						VStack {
							Text(DateTools.buildDateLarge(input: dateObj.date))
								.frame(maxWidth: .infinity)
						}
						.padding(.vertical, 10)
						.background(Color("BackgroundAlt"))
						.cornerRadius(5)
					}
					
					HStack {
						
						VStack (spacing:5) {
							Text("From")
								.foregroundColor(Color("TextSecondary"))
								.font(.system(size:14))
								.frame(maxWidth: .infinity, alignment:.leading)
							
							Button {
								if selected != .From {
									selected = .From
								}
							} label: {
								
								VStack(spacing:10) {
									Text(DateTools.getDateString(fromDate))
										.frame(maxWidth: .infinity)
									
									Text(DateTools.getHourString(fromDate))
										.frame(maxWidth: .infinity)
								}
								.padding(.vertical, 10)
								.background(
									
											RoundedRectangle(cornerRadius: 5, style: .continuous)
												.stroke(Color("LabelBackgroundFocus"),
																lineWidth: selected == .From ? 2 : 0)
												.background(Color("BackgroundAlt"))
											
								)
							}
						}

						VStack (spacing:5) {
							Text("To")
								.foregroundColor(Color("TextSecondary"))
								.font(.system(size:14))
								.frame(maxWidth: .infinity, alignment:.leading)
							
							Button {
								if selected != .To {
									selected = .To
								}
							} label: {
								
								VStack(spacing:10) {
									Text(DateTools.getDateString(toDate))
										.frame(maxWidth: .infinity)
									
									Text(DateTools.getHourString(toDate))
										.frame(maxWidth: .infinity)
								}
								.padding(.vertical, 10)
								.background(
									
											RoundedRectangle(cornerRadius: 5, style: .continuous)
												.stroke(Color("LabelBackgroundFocus"),
																lineWidth: selected == .To ? 2 : 0)
												.background(Color("BackgroundAlt"))
											
								)
	
							}
						}
						
					}
					
					SearchQueryDatePopupRelative(queryDate: dateObj.date,
																			 dateObject: (selected == .From ? $fromDate : $toDate),
																			 selected: $selected)
					
					VStack(spacing:5){
						Text("Field")
							.foregroundColor(Color("TextSecondary"))
							.font(.system(size:14))
							.frame(maxWidth: .infinity, alignment:.leading)
						
						VStack {
							
							Text("Date field defaults to the selected field. You can change to any other Date field.")
								.padding(.bottom, 5)
							
							Button {
								showingDateList=true
							} label: {
								HStack {
									Text(localField?.squashedString ?? "")
									Image(systemName: "chevron.right")
								}
								.padding(.vertical, 10)
								.frame(maxWidth: .infinity)
								.foregroundColor(.white)
								.background(Color("Button"))
								.cornerRadius(5)
							}
							
							
						}
						.padding(10)
						.background(Color("BackgroundAlt"))
						.cornerRadius(5)
					}
					
					Button {
						
						filterObject.dateField = localField
						filterObject.absoluteRange = AbsoluteDateRangeObject(from:fromDate, to:toDate)

							withAnimation(Animation.linear(duration: 0.3)){
								showDateInputView=nil
							}
//						}
						
					} label: {
						Text("Set")
							.padding(.vertical, 10)
							.frame(maxWidth: .infinity)
							.background(Color("PositiveButton"))
							.foregroundColor(.white)
							.cornerRadius(5)
					}
					
				}
				.padding(.horizontal, 15)
				.padding(.top, 10)
				
			}
			
		}
		.navigationDestination(isPresented:$showingDateList, destination: {
			DateSheetListView(fields: fields,
												localField: $localField)
												
		})
		.offset(x:offset, y:1)
		.navigationTitle("Date Query")
		.background(Color("Background"))
		.onAppear {
			if let field = showDateInputView?.field {
				localField = field
			}
			
			if let dateOb = showDateInputView?.date {
				fromDate = dateOb
				toDate = dateOb
			}
		}
		.onDisappear {
			if !showingDateList {
				showDateInputView=nil
			}
		}
	}
}

