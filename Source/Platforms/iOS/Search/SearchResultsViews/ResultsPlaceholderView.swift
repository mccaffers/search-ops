// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct ResultsPlaceholderView: View {
  
  @State var refresh=UUID()
  @State var inView = true
  @State var appeared = false
  @Binding var loading : Bool
  @Binding var initComplete : Bool
  
  @State private var rowCount = 50
  @State private var columnCount = 0
  @EnvironmentObject var orientation : Orientation
  
  func refreshContent() {
    withAnimation (Animation.linear(duration: 0.4)){
      refresh=UUID()
    }
    if loading || !initComplete {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if loading || !initComplete {
          refreshContent()
        }
      }
    }
  }
  
  var body: some View {
    ScrollView(showsIndicators: false) {
      
      Grid(alignment: .leading,
           horizontalSpacing: 5,
           verticalSpacing: 5) {
        GridRow {
          ForEach((1...10), id: \.self) { index in
            RoundedRectangle(cornerRadius: 5)
              .fill(Color("BackgroundAlt").opacity(Double.random(in: 0.4...0.9)))
              .frame(height: 20)
              .frame(maxWidth: .infinity)
              .transition(.scale(scale: 1, anchor: .leading))
          }	.frame(maxWidth: .infinity)
        }	.frame(maxWidth: .infinity)
        
        ForEach((1...rowCount).reversed(), id: \.self) { index in
          GridRow {
            ForEach((1...10).reversed(), id: \.self) { indexTwo in
              VStack {
                RoundedRectangle(cornerRadius: 5)
                  .fill(Color("BackgroundAlt").opacity(Double.random(in: 0.4...0.9)))
                  .frame(height: 20)
                  .frame(maxWidth: .infinity)
                  .transition(.scale(scale: 1, anchor: .leading))
              }	.frame(maxWidth: .infinity)
            }
            
          }	.frame(maxWidth: .infinity)
        }
        Text("").id(refresh)
      }	.frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 10)
    .onChange(of: orientation.orientation) { newValue in
      print(newValue.rawValue)
      let screenRect = UIScreen.main.bounds
      let cellHeight: CGFloat = 20 // Adjust as needed
      
      rowCount = Int(screenRect.height / cellHeight)
      refresh=UUID()
    }
    .onAppear {
      
      let screenRect = UIScreen.main.bounds
      let cellHeight: CGFloat = 20 // Adjust as needed
      
      rowCount = Int(screenRect.height / cellHeight)

      if loading {
        refreshContent()
      } else if !appeared {
        appeared=true
        if !initComplete {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshContent()
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            initComplete = true
          }
        }
      }
    }
    .onChange(of: loading) { newValue in
      if newValue {
        refreshContent()
      }
    }
  }
}
#endif
