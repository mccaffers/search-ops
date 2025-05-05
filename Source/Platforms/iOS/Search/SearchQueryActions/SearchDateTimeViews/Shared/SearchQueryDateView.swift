// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI


struct SearchQueryDateView: View {

//    @EnvironmentObject var dateObj : DateRangeObj
    @EnvironmentObject var filterObject : FilterObject
	
		@Binding var localRelativeRangeObject : RelativeRangeFilter
        
    func dateString(_ dateInput: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM YYYY"
        return dateFormatter.string(from: dateInput)
    
    }
    
    func dayString(_ dateInput: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Full day, Monday
        return dateFormatter.string(from: dateInput)
    
    }
    
    func timeString(_ dateInput: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: dateInput)
    
    }
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

//    RunLoop.main.add(myTimer, forMode: .common)
    
    @State var fromDate : Date = Date.now
    @State var active : Bool = true
    
    func UpdateDate() {
//        fromDate = dateObj.GetFromTime()
        fromDate = localRelativeRangeObject.GetFromTime() ?? Date.now
        print("trigger " + fromDate.description)
    }
    
//    func myTimer() async {
//
//        try? await Task.sleep(seconds: 1)
//        if active {
//            UpdateDate()
//            await myTimer()
//        }
//
//        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
//            print(active)
//            if !active {
//                print("invalidating")
//                countdownTimer?.invalidate()
//                countdownTimer=nil
//            } else {
//
//            }
//
//        })
//
//    }
    
    @State var labelBackgrounds : Color = Color("LabelBackgroundFocus")
    
    var body: some View {
        VStack (alignment:.leading, spacing:0) {
            
            VStack(alignment: .leading) {
                
                HStack(spacing:5){
                    HStack {
											Text("From")
												.foregroundColor(Color("TextSecondary"))
												.font(.system(size:14))
												.frame(maxWidth: .infinity, alignment:.leading)
											
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    HStack {
											Text("To")
												.foregroundColor(Color("TextSecondary"))
												.font(.system(size:14))
												.frame(maxWidth: .infinity, alignment:.leading)
											
                        
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 15)
                .padding(.top, 15)
                
            }
        
            
            HStack (spacing:10) {

                ZStack {
                    VStack(alignment:.center, spacing:0){
                        
                       
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight:.infinity)
                    .background(.clear)
                    .cornerRadius(5)
                    
                    VStack(alignment:.center, spacing:0){
                        
                        VStack (spacing:5) {
                            Text(dateString(fromDate))
                            Text(timeString(fromDate))
                        }
                        .frame(maxWidth: .infinity, maxHeight:.infinity)
                        
                    }
                    .background(Color("Button"))
										.foregroundColor(.white)
                    .cornerRadius(5)
                }

                VStack(spacing:0){
                    ZStack {
                        VStack(alignment:.center, spacing:0){
                            
                            VStack (spacing:5) {
                                HStack (alignment:.center) {
                                    Text("Now")
                                        .font(.system(size: 18))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight:.infinity)
                            
                        }.background(Color("LabelBackgrounds")).cornerRadius(5)
                        
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Color("LabelBackgroundBorder"))
                                    .font(.system(size: 18))
                            }.frame(maxWidth:.infinity).padding(5)
                            
                        }
                    }
                }
            }.frame(height: 80)
            .padding(.horizontal, 15)
            .padding(.top, 5)
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    Text(Image(systemName: "arrowshape.right.fill"))
//                        .font(.system(size: 20))
//                        .foregroundColor(Color("LabelBackgroundBorder"))
//                    Spacer()
//                }
//                Spacer()
//            }.frame(maxWidth: .infinity)
        }
        .onReceive(timer){ _ in

                // Delay of 7.5 seconds (1 second = 1_000_000_000 nanoseconds)
               UpdateDate()


        }
        .onAppear {
//            dateObj.Refresh()

//
//            Task {
//                try? await Task.sleep(seconds: 0.5)
////                await myTimer()
//
//            }
            active = true
            
//            Task {
//                try? await Task.sleep(seconds: 0.5)
//                _ = timer.connect()
//            }
        }
        .onDisappear {
            print("hiding view")
            active = false
        }
//        .onChange(of: dateObj.refresh) { _ in
//            UpdateDate()
//        }
    }
}
