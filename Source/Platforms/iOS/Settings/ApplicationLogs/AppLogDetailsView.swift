// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct AppLogDetailsView: View {
  
  var myTitle : String = ""
  @State var contents : [String] = []
  
  var body: some View {
    ScrollView {
      VStack {
        ForEach(contents.indices, id: \.self) { index in
          VStack {
            HStack {
              Text(contents[index].split(separator: "|")[0].trimmingCharacters(in: .whitespacesAndNewlines))
              Text("|")
              Text(contents[index].split(separator: "|")[1].trimmingCharacters(in: .whitespacesAndNewlines))
            }
              .font(.subheadline)
              .foregroundStyle(.gray)
              .frame(maxWidth: .infinity, alignment: .leading)
            Text(contents[index].split(separator: "|")[2].trimmingCharacters(in: .whitespacesAndNewlines))
              .frame(maxWidth: .infinity, alignment: .leading)
          }.frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 5)
        }
      }.padding(.horizontal, 20)
        .padding(.bottom, 5)
    }
    .onAppear {
      SystemLogger().flush()
      contents = SystemLogger().readLog(myTitle)?.split(separator: "\n").map(String.init) ?? []
    }

    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Background"))
    .navigationTitle(myTitle)
    .navigationBarTitleDisplayMode(.large)
  }
}


#Preview {
  AppLogDetailsView()
}

#endif
