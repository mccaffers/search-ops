// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
// maybe NSViewRepresentable here
struct CustomTextView: UIViewRepresentable {
    
    var text: String
  
    let textView = UITextView()
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextView
        
        init(_ parent: CustomTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            textView.isEditable = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        textView.delegate = context.coordinator
        textView.dataDetectorTypes = .link
        textView.becomeFirstResponder()
        textView.isEditable = false
        textView.backgroundColor = UIColor(Color("Background"))
        
        
//        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineHeightMultiple = 30
//        paragraphStyle.maximumLineHeight = 30
//        paragraphStyle.minimumLineHeight = 30
//        let ats = [NSAttributedString.Key.paragraphStyle: paragraphStyle]
//        textView.attributedText = NSAttributedString(string: "you string here", attributes: ats)
        textView.font = .systemFont(ofSize: 16)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#endif
