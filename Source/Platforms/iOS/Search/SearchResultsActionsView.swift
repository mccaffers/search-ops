// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import SwiftyJSON

struct SearchResultsActionsView: View {
    
    @Binding var showingAllButtons : Bool
    var hitCount : Int
   
    @Binding var postRequestUpdate: UUID
    
    @State var unsearchedFilter = false
    
    @Binding var page : Int
    var pageCount : Int
 
    @EnvironmentObject var selectedHost: HostDetailsWrap
    
    @EnvironmentObject var filterObject : FilterObject
	
    
    var body: some View {
        VStack(
                alignment: .leading,
                spacing: 10
        )  {
            
            if unsearchedFilter {
                HStack {
                    Text(Image(systemName: "exclamationmark.triangle"))
										.foregroundColor(.white)
                        .font(.system(size: 20))
                    
                    Text("Filter changed. Search to load results.")
												.foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 8)
                .redacted(reason:  hitCount == 0 ? .placeholder : [])
                .disabled(hitCount == 0)
                .mask(Color.black.opacity(hitCount == 0 ? 0.2 : 1))
                .background(Color("Button"))
						}
					else {
                
                HStack (alignment:.center, spacing:5) {
                    
                    Button {
                        if page > 1 {
                            page-=1
                        }
                    } label: {
                        VStack(
                            alignment: .leading,
                            spacing: 10
                        ) {
                            HStack {
                                Text(Image(systemName: "chevron.left"))
                                Text((page-1).string)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                        }
                        .foregroundColor(.white)
                        .background(Color("Button"))
                        .cornerRadius(5)
                        .redacted(reason: page == 1 ? .placeholder : [])
                        .disabled(page == 1)
                    }
                    
                    
                    VStack (spacing:0) {
                        
                        Text(hitCount.string + " hits")
                        Text("Page " + page.string + " of " + pageCount.string)
                            .font(.system(size: 12))
                        
                        HStack {
                            Spacer()
                        }
                    }.font(.system(size: 14))
										.foregroundColor(.white)
                    
                    
                    Button {
                        if page < pageCount {
                            page+=1
                        }
                        
                    } label: {
                        VStack(
                            alignment: .leading,
                            spacing: 10
                        ) {
                            HStack {
                                Text((page+1).string)
                                Text(Image(systemName: "chevron.right"))
                                
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                        }
                        .foregroundColor(.white)
                        .background(Color("Button"))
                        .cornerRadius(5)
                    }
                    .redacted(reason: page == pageCount ? .placeholder : [])
                    .disabled(page == pageCount)
                    
                    
                    
                    
                    
                    
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 8)
                .redacted(reason:  hitCount == 0 ? .placeholder : [])
                .disabled(hitCount == 0)
                .mask(Color.black.opacity(hitCount == 0 ? 0.2 : 1))
                .background(Color("Button"))
                
            }
          
        }
        .onChange(of: postRequestUpdate) { _ in
            unsearchedFilter=false
        }
        .onChange(of: filterObject.id) { _ in
            if hitCount != 0 {
                unsearchedFilter=true
            } else {
                unsearchedFilter=false
            }
        }
        
//        .transaction { (tx: inout Transaction) in
//            tx.disablesAnimations = false
////            tx.animation =
//        }

    }
}
