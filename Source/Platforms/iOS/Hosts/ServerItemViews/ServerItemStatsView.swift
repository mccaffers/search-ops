// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct ServerItemStatsView: View {
    
    var item: HostDetails

    var body: some View {
        VStack(
                alignment: .leading,
                spacing: 10
        ) {
            
            VStack {
                HStack (spacing:5) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                    Text("Cluster")
                }
                .font(.system(size: 16))
                .foregroundColor(Color("TextColor"))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 20)
            .padding(.vertical, 15)
            .background(Color("BackgroundAlt"))
            
            VStack(
                    alignment: .leading,
                    spacing: 15
            ) {
                HStack {
                    Text("Indices: ")
                        .frame(minWidth: 100, alignment: .trailing)
                    Text("0")
                    Spacer()
                }.padding(.leading, 10)
                
                HStack {
                    Text("Shards: ")
                        .frame(minWidth: 100, alignment: .trailing)
                    Text("Green")
                    Spacer()
                }.padding(.leading, 10)
                
                HStack {
                    Text("Nodes: ")
                        .frame(minWidth: 100, alignment: .trailing)
                    Text("0")
                    Spacer()
                }.padding(.leading, 10)
                
                HStack {
                    Text("Status: ")
                        .frame(minWidth: 100, alignment: .trailing)
                    Text("Green")
                    Spacer()
                }.padding(.leading, 10)
            }
            .foregroundColor(Color("TextColor"))
            .font(.system(size: 16))
            .padding(5)
            
            
            
        }.padding(.bottom, 10)
    }
}
