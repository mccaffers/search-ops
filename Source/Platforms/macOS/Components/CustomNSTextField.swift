// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

struct CustomNSTextField: NSViewRepresentable {
  
  class Coordinator: NSObject, NSTextFieldDelegate {
    var parent: CustomNSTextField
    
    init(parent: CustomNSTextField) {
      self.parent = parent
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
      print("searching")
      parent.onSubmit()
    }
    
    func controlTextDidChange(_ obj: Notification) {
      if let textField = obj.object as? NSTextField {
        parent.text = textField.stringValue
      }
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
      
      if let textField = control as? NSTextField {
        DispatchQueue.main.async {
          if let editor = textField.currentEditor() {
            editor.moveToEndOfDocument(nil)
          }
        }
      }
      return true
    }
  }
  
  @Binding var text: String
  var onSubmit: () -> Void
  
  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }
  
  func makeNSView(context: Context) -> NSTextField {
    let textField = NSTextField()
    textField.delegate = context.coordinator
    textField.isBezeled = false
    textField.isEditable = true
    textField.isSelectable = true
    
    textField.backgroundColor = NSColor(Color.clear)
    return textField
  }
  
  func updateNSView(_ nsView: NSTextField, context: Context) {
    if nsView.stringValue != text {
      nsView.stringValue = text
    }
  }
}


struct BetterTextEditor: NSViewRepresentable {
  
  var textView = NSTextView.scrollableTextView()
  @Binding var text: String
  
  func makeNSView(context: Context) -> NSScrollView {
    let documentView = (textView.documentView as! NSTextView)
    
    // Add the click gesture recognizer
    let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
    documentView.addGestureRecognizer(clickGesture)
    
    documentView.backgroundColor = NSColor(Color("BackgroundAlt"))
    documentView.delegate = context.coordinator
    documentView.isEditable = true
    
    let scroll = NSScrollView()
    scroll.hasVerticalScroller = true
    scroll.documentView = documentView
    scroll.drawsBackground = false
    
    return scroll
  }
  
  func updateNSView(_ view: NSScrollView, context: Context) {
    let documentView = (view.documentView as? NSTextView)
    
    documentView?.string = text
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  var onClick: () -> Void
  
  class Coordinator: NSObject, NSTextViewDelegate{
    
    @objc func handleClick(_ sender: NSClickGestureRecognizer) {
      // Call the closure passed from SwiftUI
      parent.onClick()
    }
    
    var parent: BetterTextEditor
    
    init(_ parent: BetterTextEditor) {
      self.parent = parent
    }
    
    func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }
      
      self.parent.text = textView.string
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool { return true }
  }
}
#endif
