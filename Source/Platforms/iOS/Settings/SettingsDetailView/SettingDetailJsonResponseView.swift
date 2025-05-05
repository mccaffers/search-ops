// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SettingDetailJsonResponseView: View {

	var title : String
	var input : String
	var index : String
	
	@State var showingJsonResponse = false
	@State var renderingJsonResponse = false
	@State var jsonResponse = JSONResponse()
	
	var body: some View {
		VStack {
			VStack {
				HStack {
					Text(title)
						.foregroundColor(Color("TextColor"))
					
					Spacer()
					Button {
						//							Task { @MainActor in
						showingJsonResponse.toggle()
						renderingJsonResponse.toggle()
//						jsonResponse = ""
						
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							Task {
								jsonResponse = await SettingAppLogs.render(input: input)
								renderingJsonResponse = false
							}
						}
						//							}
					} label: {
						Text(showingJsonResponse ? "Hide":"Show")
							.padding(10)
							.background(Color("Background"))
							.cornerRadius(5)
					}
					
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.horizontal, 15)
			}
			.padding(.vertical, 10)
			.background(Color("BackgroundAlt"))
			
			if showingJsonResponse {
				if renderingJsonResponse {
					VStack {
						Text("Attempting to render the body as JSON")
						ProgressView()
							.controlSize(.regular)
					}.frame(maxWidth: .infinity)
						.padding(.vertical, 10)
				} else {
					if jsonResponse.error {
						HStack (spacing:15) {
							Image(systemName: "exclamationmark.triangle")
								.font(.system(size: 18))
								.foregroundColor(.orange)
							SettingDetailJsonViewer(text:jsonResponse.contents)
						}
							.padding(.horizontal, 20)
							.padding(.top, 10)
							.padding(.bottom, 30)
					} else {
						SettingDetailJsonViewer(text: jsonResponse.contents)
							.padding(.horizontal, 15)
					}
				}
			}
		}
	}
}
