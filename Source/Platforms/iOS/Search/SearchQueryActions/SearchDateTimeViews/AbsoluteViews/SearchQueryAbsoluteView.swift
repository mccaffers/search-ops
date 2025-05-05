// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI


struct SearchQueryAbsoluteView: View {

//    @EnvironmentObject var dateObj : DateRangeObj
    @ObservedObject var localDateObject : AbsoluteDateRangeObject = AbsoluteDateRangeObject()
    @EnvironmentObject var filteredObject: FilterObject
//    @ObservedObject var absoluteDateRange : AbsoluteDateRangeObject?

    @Environment(\.dismiss) private var dismiss
    
    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        )  {
					
					HStack {
						VStack(spacing:5) {
							HStack {
								Text("From")
									.foregroundColor(Color("TextSecondary"))
									.font(.system(size:14))
									.frame(maxWidth: .infinity, alignment:.leading)
							}
							.frame(maxWidth: .infinity, alignment:.leading)
							
							VStack(alignment:.center, spacing:0){
									
									VStack (spacing:10) {
										Text(DateTools.getDateString(localDateObject.from))
										Text(DateTools.getHourString(localDateObject.from))
									}
									.frame(maxWidth: .infinity)
									.padding(.vertical, 10)
									
							}
							.background(Color("BackgroundAlt"))
							.cornerRadius(5)
							
//							Text(localDateObject.from.formatted())
//								.frame(maxWidth: .infinity, alignment:.center)
//								.padding(.vertical, 10)
//								.background(Color("BackgroundAlt"))
//								.cornerRadius(5)
//
							
								
								HStack {
									Text(Image(systemName: "calendar"))
										.foregroundColor(.white)
									Text("Date")
										.foregroundColor(.white)
								}
								.frame(maxWidth: .infinity, alignment:.center)
								.padding(.vertical, 10)
								.background(Color("Button"))
								.cornerRadius(5)
								.overlay{ //MARK: Place the DatePicker in the overlay extension
									DatePicker(
										"",
										selection: $localDateObject.from,
										displayedComponents: [.date]
									)
									.colorScheme(.dark)
									.accentColor(Color("Button"))
									.blendMode(.destinationOver) //MARK: use this extension to keep the clickable functionality
								}
								
								
								HStack {
									Text(Image(systemName: "clock"))
										.foregroundColor(.white)
									Text("Time")
										.foregroundColor(.white)
								}
								.frame(maxWidth: .infinity, alignment:.center)
								.padding(.vertical, 10)
								.background(Color("Button"))
								.cornerRadius(5)
								.overlay{ //MARK: Place the DatePicker in the overlay extension
									DatePicker(
										"",
										selection: $localDateObject.from,
										displayedComponents: [.hourAndMinute]
									)
									.colorScheme(.dark)
									.accentColor(Color("Button"))
									.blendMode(.destinationOver) //MARK: use this extension to keep the clickable functionality
								}
								
						
						}
						
						VStack(spacing:5) {
						HStack {
							Text("To")
								.foregroundColor(Color("TextSecondary"))
								.font(.system(size:14))
								.frame(maxWidth: .infinity, alignment:.leading)
						}
						.frame(maxWidth: .infinity, alignment:.leading)
//
//						Text(localDateObject.to.formatted())
//							.frame(maxWidth: .infinity, alignment:.center)
//							.padding(.vertical, 10)
//							.background(Color("BackgroundAlt"))
//							.cornerRadius(5)
						
							VStack(alignment:.center, spacing:0){
									
									VStack (spacing:10) {
										Text(DateTools.getDateString(localDateObject.to))
										Text(DateTools.getHourString(localDateObject.to))
									}
									.frame(maxWidth: .infinity)
									.padding(.vertical, 10)
									
							}
							.background(Color("BackgroundAlt"))
							.cornerRadius(5)
								
								HStack {
									Text(Image(systemName: "calendar"))
										.foregroundColor(.white)
									Text("Date")
										.foregroundColor(.white)
								}
								.frame(maxWidth: .infinity, alignment:.center)
								.padding(.vertical, 10)
								.background(Color("Button"))
								.cornerRadius(5)
								.overlay{ //MARK: Place the DatePicker in the overlay extension
									DatePicker(
										"",
										selection: $localDateObject.to,
										displayedComponents: [.date]
									)
									.colorScheme(.dark)
									.accentColor(Color("Button"))
									.blendMode(.destinationOver) //MARK: use this extension to keep the clickable functionality
								}
								
								
								HStack {
									Text(Image(systemName: "clock"))
										.foregroundColor(.white)
									Text("Time")
										.foregroundColor(.white)
								}
								.frame(maxWidth: .infinity, alignment:.center)
								.padding(.vertical, 10)
								.background(Color("Button"))
								.cornerRadius(5)
								.overlay{ //MARK: Place the DatePicker in the overlay extension
									DatePicker(
										"",
										selection: $localDateObject.to,
										displayedComponents: [.hourAndMinute]
									)
									.colorScheme(.dark)
									.accentColor(Color("Button"))
									.blendMode(.destinationOver) //MARK: use this extension to keep the clickable functionality
								}
								
								
							
							
						}
					}
					.padding(.top, 15)
					.padding(.bottom, 10)
            
            
            Button {
                filteredObject.absoluteRange=AbsoluteDateRangeObject()
                filteredObject.absoluteRange?.from=localDateObject.from
                filteredObject.absoluteRange?.to=localDateObject.to
                
                filteredObject.relativeRange = nil
                dismiss()
            } label: {
                HStack {
                    Text("Save")
                    Text(Image(systemName: "square.and.arrow.down"))
                }
                    .frame(maxWidth: .infinity, alignment:.center)
                    .padding(.vertical, 15)
                    .background(Color("PositiveButton"))
										.foregroundColor(.white)
                    .cornerRadius(5)
            }
            
        }
        .padding(.horizontal, 15)
        .onAppear {
            if filteredObject.absoluteRange != nil {
                localDateObject.from = filteredObject.absoluteRange?.from ?? Date.now
                localDateObject.to = filteredObject.absoluteRange?.to ?? Date.now
            }
        }
       
    }
}
