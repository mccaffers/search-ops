// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct ReleaseNotesList: View {
  
  // Need a boolean for navigationDestination
  @State var showReleaseDetails : Bool = false
  @State var showingRelease = "" {
    didSet {
      showReleaseDetails = true
    }
  }

  var body: some View {
    ScrollView{
      VStack(spacing:25) {

        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 3))!,
                               buttonText: "Version 2.0.2",
                               buttonDescription: "Fixing bugs. Updating screenshots and video previews on Apple App Store",
                               buttonAction: {  },  isLatest: true)
        .padding(.top, 15)
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 3))!,
                               buttonText: "Version 2.0.1",
                               buttonDescription: "Fixed a minor bug, the default date field would override the sort field",
                               buttonAction: {  })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 2))!,
                               buttonText: "Version 2.0",
                               buttonDescription: "Recent Searches, Refresh Timer, Default Date Range and a macOS version",
                               buttonAction: { showingRelease = "Version 2.0" },
                               activeButton: true)

        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 5, day: 12))!,
                               buttonText: "Version 1.94",
                               buttonDescription: "Fixed multiple bugs, UI updates and prep for macOS version",
                               buttonAction: { showingRelease = "Version 1.94" },
                               activeButton: true)
                  
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 7))!,
                               buttonText: "Version 1.93",
                               buttonDescription: "Fixed an issue in Date Range queries with ISO UTC offsets (eg +01:00 or -08:00)",
                               buttonAction: {  })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 29))!,
                               buttonText: "Version 1.92",
                               buttonDescription: "Added support for self signed certificates",
                               buttonAction: { })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 27))!,
                               buttonText: "Version 1.91",
                               buttonDescription: "Fixed an issue with the forming URL paths with custom ports",
                               buttonAction: { })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!,
                               buttonText: "Version 1.9",
                               buttonDescription: "Update to protect the application from crashing when deleting a host",
                               buttonAction: {  })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 5))!,
                               buttonText: "Version 1.8",
                               buttonDescription: "Update to manage empty nested JSON objects",
                               buttonAction: {  })
 
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2023, month: 11, day: 2))!,
                               buttonText: "Version 1.7",
                               buttonDescription: "Fixes an issue with the host details, which was showing static text",
                               buttonAction: {  })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2023, month: 10, day: 29))!,
                               buttonText: "Version 1.6",
                               buttonDescription: "Added support for iPad",
                               buttonAction: {  })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2023, month: 9, day: 14))!,
                               buttonText: "Version 1.5",
                               buttonDescription: "Added JSON viewer when looking at individual documents",
                               buttonAction: {  })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2023, month: 9, day: 4))!,
                               buttonText: "Version 1.4",
                               buttonDescription: "Added JSON viewer when looking at individual documents",
                               buttonAction: {  })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2023, month: 8, day: 12))!,
                               buttonText: "Version 1.3",
                               buttonDescription: "Refactoring business logic behind the scenes",
                               buttonAction: {  })
        
        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2023, month: 8, day: 5))!,
                               buttonText: "Version 1.2",
                               buttonDescription: "Refactoring business logic behind the scenes",
                               buttonAction: {  })

        ReleaseNotesListButton(releaseDate: Calendar.current.date(from: DateComponents(year: 2023, month: 7, day: 27))!,
                               buttonText: "Version 1",
                               buttonDescription: "Released Search Ops App 🎉",
                               buttonAction: {  })
        
        Spacer()
      }
    }
    
    .navigationTitle("Release Notes")
    .frame(maxWidth: .infinity)
    .background(Color("Background"))
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
    .navigationDestination(isPresented: $showReleaseDetails) {
      if showingRelease == "Version 1.94" {
        Version_1_94(title: showingRelease, lastSeenVersionNotes: .constant(""))
      } else if showingRelease == "Version 2.0" {
        Version_2_0(title: showingRelease)
      }
    }
  }
}

//#Preview {
//    ReleaseNotesList()
//}
#endif
