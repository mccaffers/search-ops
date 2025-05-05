// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

import Charts
#if os(iOS)

struct AreaChartComponent: View {
  var body: some View {
    VStack {
      
      ZStack {
        // Drawing the grid and labels
        VStack {
          ForEach(0..<6) { i in
            HStack {
              Text("\(100 - i * 10)%")
                .frame(width: 50, alignment: .trailing)
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            }
          }
        }
        
        
        // Drawing the area chart
        AreaChartView()
          .fill(LinearGradient(gradient: Gradient(colors: [Color("TextColor").opacity(0.6), Color("TextColor").opacity(0)]), startPoint: .top, endPoint: .bottom))
          .padding(.leading, 60)
      }
      .frame(height: 200)
      .clipped() // Ensures that the view does not overflow its bounds
    }
  }
}

struct AreaChartView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Define multiple points for the chart
        let points = [
            (x: 0.0, y: 0.8),   // Start at 60%
            (x: 0.2, y: 0.58),  // Point at 65%
            (x: 0.4, y: 0.60),  // Point at 70%
            (x: 0.6, y: 0.55),  // Point at 75%
            (x: 0.8, y: 0.40),  // Point at 80%
            (x: 1.0, y: 0.35)   // End at 85%
        ]

        // Start at the bottom left of the chart
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        
        // Add lines to each point
        for point in points {
            let xPos = rect.width * CGFloat(point.x)
            let yPos = rect.maxY * CGFloat(point.y)
            path.addLine(to: CGPoint(x: xPos, y: yPos))
        }
        
        // Finish by drawing a line to the bottom right and closing the path
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

struct TextWithAttributedString: UIViewRepresentable {

    var attributedString: NSAttributedString
  let textDidChange: (UITextView) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
      textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      
      
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
      
   
//      textView.attributedText = NSAttributedString(attributedString:  self.attributedString)
//      textView.font = .systemFont(ofSize: 16)
      
        textView.attributedText = self.attributedString
      textView.backgroundColor = .clear
      DispatchQueue.main.async {
            self.textDidChange(textView)
          }

    }
}

struct JSONColoredTextView: View {
  public init(jsonString:String) {
    self.jsonString = jsonString
  }
  
  var jsonString : String
    
    
    let minHeight: CGFloat = 0
    @State private var height: CGFloat? = nil


    private func textDidChange(_ textView: UITextView) {
      self.height = max(textView.contentSize.height, minHeight)
    }
  
    var body: some View {
        
     
          TextWithAttributedString(attributedString: attributedJson2(), textDidChange: self.textDidChange)
            .frame(height: height ?? minHeight)
                          .background(.clear)
        
    }

  func attributedJson2() -> NSMutableAttributedString {
    
    let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = 30
    paragraphStyle.maximumLineHeight = 30
    paragraphStyle.minimumLineHeight = 30
    let ats = [NSAttributedString.Key.paragraphStyle: paragraphStyle]
    
    let redColor = UIColor.white
    let attributedString = NSMutableAttributedString(string: jsonString, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)])
    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(Color("LabelBackgroundFocus")), range: NSRange(location: 0, length: jsonString.count))
//    attributedString.addAttributes(ats, range: NSRange(location: 0, length: jsonString.count))
    // Define the regex pattern for brackets and braces
    let pattern = "[\\{\\}\\[\\]]"
    


    do {
      // Create a regular expression
      let regex = try NSRegularExpression(pattern: pattern, options: [])
      
      // Perform matching on the entire string length
      let matches = regex.matches(in: jsonString, options: [], range: NSRange(location: 0, length: jsonString.utf16.count))
      
      // Iterate over all matches
      for match in matches {
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: redColor, range: match.range)
      }
      
    } catch {
      print("Regex error: \(error)")
    }
    

    return attributedString
  }
  
    
    func attributedJson() -> NSMutableAttributedString {

      var attributedString = NSMutableAttributedString(string: jsonString)
        
        // Default font and color
//        attributedString.foregroundColor = .black
        
        // Set color for brackets
        let bracketsColor = Color.red
        let bracketsPattern = "[\\{\\}\\[\\]]"

        // Apply red color to brackets using regex
        if let bracketsRegex = try? NSRegularExpression(pattern: bracketsPattern, options: []) {
            let matches = bracketsRegex.matches(in: jsonString, options: [], range: NSRange(location: 0, length: jsonString.utf16.count))
            for match in matches {
              
              if match.range.location != NSNotFound
                  {
                let greenColor = UIColor(red: 10/255, green: 190/255, blue: 50/255, alpha: 1)
                // create the attributed colour
                let attributedStringColor = [NSAttributedString.Key.foregroundColor : greenColor];
                // create the attributed string
               let temp = NSAttributedString(string: "Hello World!", attributes: attributedStringColor)
                // Set the label
                attributedString.replaceCharacters(in: match.range, with: temp)

                  }
            }
        }
        
        return attributedString
    }
  
  func transform(_ input: String, from: String, to: String, with color: Color) -> AttributedString {
    var attInput = AttributedString(input)
    let _ = input.components(separatedBy: from).compactMap { sub in
      (sub.range(of: to)?.lowerBound).flatMap { endRange in
        let s = String(sub[sub.startIndex ..< endRange])
        // use `s` for just the middle string
        if let theRange = attInput.range(of: (from + s + to)) {
          attInput[theRange].foregroundColor = color
        }
      }
    }
    return attInput
  }
}


struct Version_1_94: View {
  
  var showContinueButton : Bool = false
  var title = "New Update"
  
  @State private var animate = false
  @State private var showHeader = false
  @State private var showText = false
  @State private var showText2 = false
  @State private var isVisible = true
  @State private var opacity = 1.0
  
  @Binding var lastSeenVersionNotes : String
  var animateDuration : TimeInterval = 0.8
  @State private var showFireworks = false
  @EnvironmentObject var fireworkSettings : FireworkSettings

  var body: some View {
    
    ZStack {
      NavigationStack {
        ScrollView {
          VStack (spacing:0) {
            if title == "New Update" {
              Text("Version 1.94")
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showText ? 1 : 0)  // Start with hidden text
                .animation(.easeInOut(duration: animateDuration), value: showText)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
            }
            
            VStack {
              
              Text("This release focuses on improving the internal operations of the application, fixing multiple bugs and preparing the codebase to support macOS.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .opacity(showText ? 1 : 0)  // Start with hidden text
                .animation(.easeInOut(duration: 0.5), value: showText)
                .onAppear {
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {  // Delay of 2 seconds
                    showText = true  // Trigger the fade-in
                  }
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {  // Delay of 2 seconds
                    showText2 = true  // Trigger the fade-in
                  }
                }
              
              HostAddDivider()
                .opacity(showText ? 1 : 0)  // Start with hidden text
                .animation(.easeInOut(duration: 0.5), value: showText)
              
            }.padding(.horizontal, 20)
              .padding(.bottom, 10)

            VStack (spacing: 15){
              
              ReleaseNotesSection(
                iconName: "ant",
                title: "Bug Fixing",
                detail: "Fixed multiple issues when parsing json objects with nested arrays",
                secondLine: "The application failed to traverse complex JSON structures and would return empty values.",
                thirdLine: "Unit tests added to test a range of JSON structures (viewable on Github, ./Tests/Resources/)",
                showDetails: true,
                animationDuration: 0.5
              )
              .opacity(showText2 ? 1 : 0)  // Start with hidden text
              .animation(.easeInOut(duration: 0.5), value: showText2)
        
              
              VStack(alignment:.leading, spacing:10) {
                
                JSONColoredTextView(jsonString: """
{
  "exception": [
    {
      "stack": [
        {
          "name": "OutOfRange"
        }
      ]
    }
  ]
}
""")
                
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .font(.system(size: 14))
              .foregroundColor(Color("TextSecondary"))
              .padding(10)
              .background(Color("BackgroundAlt"))
              .cornerRadius(5)
              .opacity(showText2 ? 1 : 0)  // Start with hidden text
              .animation(.easeInOut(duration: 0.5), value: showText2)
              
              VStack(alignment:.leading, spacing:10) {
                
                Text("exception.stack.name = OutOfRange")
                
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .font(.system(size: 14))
              .foregroundColor(Color("LabelBackgroundFocus"))
              .padding(10)
              .background(Color("BackgroundAlt"))
              .cornerRadius(5)
              .opacity(showText2 ? 1 : 0)  // Start with hidden text
              .animation(.easeInOut(duration: 0.5), value: showText2)
              .padding(.bottom, 5)
              
              ReleaseNotesSection(
                iconName: "key",
                title: "Keychain Updates",
                detail: "Keychain operations updated to support a future macOS version. One application, multiple platforms!",
                secondLine:"The Keychain provides a secure place to keep your encryption key to store your host information on disk.",
                thirdLine:"The SearchOps keychain is still local to your device, and only available to you. In the future you'll be given an option on whether you want the Keychain entry to be shared across your iCloud account for multi device use.",
                showDetails: true,
                animationDuration: 0.5
              )
              .opacity(showText2 ? 1 : 0)  // Start with hidden text
              .animation(.easeInOut(duration: 0.5), value: showText2)
              
              ReleaseNotesSection(
                iconName: "grid",
                title: "UI Updates",
                detail: "Refactored the User Interface for a cohesive color palette, and adjusted the layout to simplify user navigation",
                showDetails: true,
                animationDuration: 0.5
              )
              .opacity(showText2 ? 1 : 0)  // Start with hidden text
              .animation(.easeInOut(duration: 0.5), value: showText2)
              
              ReleaseNotesSection(
                iconName: "shippingbox",
                title: "Internal dependencies updated",
                detail: "Open source packages, realm-swift, swift-collections and SwiftyJSON updated to their latest versions",
                showDetails: true,
                animationDuration: 0.5
              )
              .opacity(showText2 ? 1 : 0)  // Start with hidden text
              .animation(.easeInOut(duration: 0.5), value: showText2)
      
              ReleaseNotesSection(
                iconName: "sparkle.magnifyingglass",
                title: "Reliability",
                detail: "Increased test coverage with more search responses, over 80% of the application unit tested and results viewable on SonarCloud (link via Github)",
                showDetails: true,
                animationDuration: 0.5
              )
              .opacity(showText2 ? 1 : 0)  // Start with hidden text
              .animation(.easeInOut(duration: 0.5), value: showText2)
              
            }
            .padding(.horizontal,20)
            
            Text("Test Coverage")
              .font(.footnote)
              .foregroundStyle(Color("TextSecondary"))
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.leading, 20)
              .padding(.top, 10)
            
              AreaChartComponent()
              .padding(.horizontal, 25)
              .padding(.trailing, 10)
              .padding(.bottom, 15)

              
              HostAddDivider()
                .opacity(showText ? 1 : 0)  // Start with hidden text
                .animation(.easeInOut(duration: 0.5), value: showText)
                .padding(.horizontal, 20)
            
              VStack (spacing: 15) {
              Text("Thanks! Feel free to send any feedback to me, my email address is in App Settings.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Color("TextSecondary"))
                .padding(.bottom, 10)
                .opacity(showText2 ? 1 : 0)  // Start with hidden text
                .animation(.easeInOut(duration: 0.5), value: showText2)
                .padding(.bottom, showContinueButton ? 0 : 20)
              
              if showContinueButton {
                Text("You can also return to view these release notes in the Settings tab")
                  .foregroundColor(Color("TextSecondary"))
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.bottom, showContinueButton ? 10 : 20)
                  .opacity(showText2 ? 1 : 0)  // Start with hidden text
                  .animation(.easeInOut(duration: 0.5), value: showText2)
                
                Button {
                  lastSeenVersionNotes = "1.94"
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    lastSeenVersionNotes = "1.94"
                  }
                  
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
                .opacity(showText2 ? 1 : 0)  // Start with hidden text
                .animation(.easeInOut(duration: 0.5), value: showText2)
                .padding(.bottom, 20)
                
              }
              
            }
              .padding(.top, 10)
              .padding(.horizontal,20)
            
          } .padding(.top, 10)
        }
       
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Text("May 2024")
                .foregroundColor(Color("TextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
#endif
        .background(Color("Background").edgesIgnoringSafeArea(.all))
   
        .frame(maxWidth: .infinity)
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {  // Delay of 2 seconds
            
            if !showContinueButton && !showFireworks {
              fireworkSettings.showFireworks = true
            }
            showFireworks = true
            
          }
         

        }
      }
      
#if os(iOS)
        if showContinueButton {
          FireworksView()
            .edgesIgnoringSafeArea(.all)
            .onAppear {
              // Delay of 5 seconds before starting the fade out animation
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
#endif
      
      
    }
  }
}
#endif
