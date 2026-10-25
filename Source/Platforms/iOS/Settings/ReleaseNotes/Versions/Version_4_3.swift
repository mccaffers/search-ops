// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct Version_4_3: View {

  var showContinueButton : Bool = false
  var title = "Version 4.3"

  @State private var showFireworks = false
  @State private var isVisible = true
  @State private var opacity = 1.0
  @EnvironmentObject var fireworkSettings : FireworkSettings
  @EnvironmentObject var orientation : Orientation
  @Environment(\.dismiss) private var dismiss
  var body: some View {

    ZStack {
      if showContinueButton {
        // Shown as the launch sheet, so it needs its own navigation bar
        NavigationStack {
          content
        }
      } else {
        // Pushed from Release Notes, so it uses the Settings stack
        content
      }

      if showContinueButton {
        FireworksView()
          .edgesIgnoringSafeArea(.all)
          .onAppear {
            // Wait 1.5 seconds before starting the fade out animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              withAnimation(.easeOut(duration: 1.5)) {
                self.opacity = 0.0
              }
              // Delay the hiding of the element to allow the animation to complete
              DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isVisible = false
              }
            }
          }
          .opacity(opacity)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .edgesIgnoringSafeArea(.all)
          .ignoresSafeArea(.all)
          .isHidden(!isVisible)
          .zIndex(0)
      }
    }
  }

  private func sectionTitle(_ text: String) -> some View {
    Text(text)
      .foregroundStyle(LinearGradient(colors: [Color("LabelBackgroundBorder"), .purple], startPoint: .trailing, endPoint: .leading))
      .font(.system(size: 26))
      .bold()
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 10)
  }

  private func bullet(_ text: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text("•")
      Text(text)
    }
  }

  private var content: some View {
    ScrollView {
      VStack (spacing:0) {
        Text("October 2026")
          .font(.subheadline)
          .foregroundStyle(Color("TextSecondary"))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 20)
          .padding(.top, 5)

        VStack(alignment: .leading, spacing:5) {
          VStack(alignment:.leading, spacing:10) {

            sectionTitle("Saved")

            Text("A new **Saved** tab keeps the searches and documents you come back to. Tap **Save** in Search to keep a search's query, time period, sort and fields, then run it again with a tap, or update it after changing it. Tap the bookmark on a document to keep it, and search for any of its values later. Saved items stay on this device.")
              .padding(.bottom, 10)

            sectionTitle("Amazon OpenSearch Service")

            Text("Hosts can now sign requests with **AWS SigV4**, so you can connect to Amazon OpenSearch Service domains with your AWS access keys. Choose **AWS Signature V4** under Authentication when adding a host.")
              .padding(.bottom, 10)

            sectionTitle("Document Details")

            Text("Show or hide individual fields when viewing a document, and numbers, booleans and other values that aren't text now display properly.")
              .padding(.bottom, 10)

            sectionTitle("Fixes")

            VStack(alignment: .leading, spacing: 8) {
              bullet("Array values now show in search results")
              bullet("The page count follows your documents per page setting")
              bullet("Pasted host addresses are tidied into scheme, host and port")
              bullet("Credentials are cleared when a host's authentication is switched to None")
              bullet("Titles in Settings display properly again")
            }
            .padding(.bottom, 10)

            sectionTitle("macOS")

            Text("The macOS app has had a big update too, with Saved documents, data views, safer delete by query and a read only mode for the API console.")
              .padding(.bottom, 10)

          }

          HostAddDivider()
            .padding(.vertical, 10)

          VStack(alignment: .leading,spacing:10) {
            HStack {
              GradientButtonView(title: "iPhone & iPad")
              GradientButtonView(title: "macOS")
            }

            HStack {
              GradientButtonView(title: "No Tracking or Analytics")
              GradientButtonView(title: "Open Source")
            }

          }
          .padding(.bottom, 20)

          if showContinueButton {

            HostAddDivider()
              .padding(.vertical, 10)

            if !orientation.isLandscape {

              VStack {
                Image(systemName: "hand.draw")
                Text("Swipe down to close")
              }
              .frame(maxWidth: .infinity)
              .font(.footnote)
              .foregroundStyle(Color("TextSecondary"))
              .padding(.bottom, 10)
            } else {
              Button {
                dismiss()
              } label: {
                Text("Continue")
                  .font(.system(size: 20))
                  .foregroundColor(.white)
                  .padding(.vertical, 15)
                  .frame(maxWidth: .infinity)
                  .background(Color("Button"))
                  .cornerRadius(5)
              }
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.bottom, 20)
            }
          }

          Spacer()

        }
        .padding(.horizontal, 20)

      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.large)
    .navigationBarBackgroundVisibleBeforeiOS26()
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
    .background(Color("Background").edgesIgnoringSafeArea(.all))
    .frame(maxWidth: .infinity)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        // Pushed from Release Notes: play the fireworks over the Settings screen
        if !showContinueButton && !showFireworks {
          fireworkSettings.showFireworks = true
        }
        showFireworks = true
      }
    }
  }
}
#endif
