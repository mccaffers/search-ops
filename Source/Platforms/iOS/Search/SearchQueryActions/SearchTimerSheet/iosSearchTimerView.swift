// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct iosSearchTimerView: View {
  
  @EnvironmentObject var orientation : Orientation
  @Environment(\.dismiss) private var dismiss
  
  @Binding var timer: Timer?
  
  var startTimer: (_ interval: TimerInterval) -> Void
  var stopTimer: () -> Void
  
  private let intervals: [(String, TimerInterval)] = [
      ("Every second", TimerInterval(value: 1, unit: .seconds)),
      ("Every 2 seconds", TimerInterval(value: 2, unit: .seconds)),
      ("Every 5 seconds", TimerInterval(value: 5, unit: .seconds)),
      ("Every 10 seconds", TimerInterval(value: 10, unit: .seconds)),
      ("Every 15 seconds", TimerInterval(value: 15, unit: .seconds)),
      ("Every 30 seconds", TimerInterval(value: 30, unit: .seconds)),
      ("Every minute", TimerInterval(value: 1, unit: .minutes)),
      ("Every 5 minutes", TimerInterval(value: 5, unit: .minutes)),
  ]
  
    var body: some View {
      NavigationStack {
        
        VStack (spacing:10) {
          
          ForEach(intervals, id: \.0) { interval in
            Button {
              if let timer = timer, timer.isValid {
                stopTimer()
              } else {
                startTimer(interval.1)
              }
              dismiss()
            } label: {
              Text(timer?.isValid ?? false ? "Cancel timer" : interval.0)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color("Button"))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(PlainButtonStyle())
          }
          
            Spacer()
          
        }
        .padding(.top, 10)
        .padding(.horizontal, 10)
        .background(Color("Background"))
        .navigationTitle("Repeat Frequency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          if orientation.isLandscape {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button {
                dismiss()
              } label: {
                Text("Close")
                  .foregroundColor(Color("TextColor"))
              }
              
            }
          }
        }
      }
      .onAppear {
        UINavigationBar.appearance() .backgroundColor = UIColor(Color("BackgroundAlt"))
      }
      .onDisappear {
        UINavigationBar.appearance().backgroundColor = UIColor(Color("Background"))
      }

    }
  
}
#endif
