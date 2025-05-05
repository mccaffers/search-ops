// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

enum TimeUnit {
    case milliseconds
    case seconds
    case minutes
    case hours
}

struct TimerInterval {
  var value: Double
  var unit: TimeUnit
}

struct macosSidebarTimerView: View {
    @Binding var timer: Timer?
    @Binding var selection: macosSearchViewEnum
    @Binding var fullScreen: Bool
    @Binding var showFilterSidebar: Bool
    
    var startTimer: (_ interval: TimerInterval) -> Void
    var stopTimer: () -> Void
    
    private let intervals: [(String, TimerInterval)] = [
        ("Every second", TimerInterval(value: 1, unit: .seconds)),
        ("Every 30 seconds", TimerInterval(value: 30, unit: .seconds)),
        ("Every minute", TimerInterval(value: 1, unit: .minutes)),
        ("Every 5 minutes", TimerInterval(value: 5, unit: .minutes)),
        ("Every 15 minutes", TimerInterval(value: 15, unit: .minutes)),
        ("Every 30 minutes", TimerInterval(value: 30, unit: .minutes))
    ]
    
    var body: some View {
      VStack(alignment: .trailing) {
          
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    Text("Refresh Frequency")
                        .font(.headline)
                    
                    ForEach(intervals, id: \.0) { interval in
                        Button {
                            if let timer = timer, timer.isValid {
                                stopTimer()
                            } else {
                                startTimer(interval.1)
                            }
                            selection = .None
                        } label: {
                            Text(timer?.isValid ?? false ? "Cancel timer" : interval.0)
                                .frame(maxWidth: .infinity)
                                .padding(5)
                                .background(Color("Button"))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(10)
                .background(Color("Background"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxWidth: 300)
            .padding(.top, fullScreen ? 85 : 80)
            .padding(.trailing, showFilterSidebar ? 305 : 5)
            
            Spacer()
        }
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
