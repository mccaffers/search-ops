// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)

/// A cursor position for the field to move to, once per id
struct TextFieldCursorRequest: Equatable {
  var id = UUID()
  var location: Int
}

struct CustomNSTextField: NSViewRepresentable {

  /// Keys the field offers to `onCommand` before handling them itself
  enum Command {
    case moveUp, moveDown, tab, newline, cancel
  }
  
  class Coordinator: NSObject, NSTextFieldDelegate {
    var parent: CustomNSTextField
    weak var textField: NSTextField?
    /// Set while updateNSView changes the text, so that isn't reported as an edit
    var isApplyingUpdate = false
    var appliedCursorRequest: UUID?
    private var selectionObserver: NSObjectProtocol?
    
    init(parent: CustomNSTextField) {
      self.parent = parent
      super.init()
      selectionObserver = NotificationCenter.default.addObserver(
        forName: NSTextView.didChangeSelectionNotification, object: nil, queue: .main
      ) { [weak self] notification in
        guard let self = self,
              let editor = notification.object as? NSTextView,
              let textField = self.textField,
              editor.delegate === textField else { return }
        self.reportEdit(editor, textChanged: false)
      }
    }
    
    deinit {
      if let selectionObserver = selectionObserver {
        NotificationCenter.default.removeObserver(selectionObserver)
      }
    }
    
    func reportEdit(_ editor: NSTextView, textChanged: Bool) {
      guard !isApplyingUpdate else { return }
      let selection = editor.selectedRange()
      parent.onEdit(editor.string, selection.length == 0 ? selection.location : nil, textChanged)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
      parent.onEndEditing()
      // Only Return searches; clicking or tabbing away doesn't
      let movement = obj.userInfo?["NSTextMovement"] as? Int
      if movement == NSTextMovement.return.rawValue {
        parent.onSubmit()
      }
    }
    
    func controlTextDidChange(_ obj: Notification) {
      if let textField = obj.object as? NSTextField {
        parent.text = textField.stringValue
        if let editor = textField.currentEditor() as? NSTextView {
          reportEdit(editor, textChanged: true)
        }
      }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
      let command: Command
      switch commandSelector {
      case #selector(NSResponder.moveUp(_:)):
        command = .moveUp
      case #selector(NSResponder.moveDown(_:)):
        command = .moveDown
      case #selector(NSResponder.insertTab(_:)):
        command = .tab
      case #selector(NSResponder.insertNewline(_:)):
        command = .newline
      case #selector(NSResponder.cancelOperation(_:)), #selector(NSTextView.complete(_:)):
        command = .cancel
      default:
        return false
      }
      return parent.onCommand(command)
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
  /// Where to put the cursor after the text is changed from outside, eg. by a suggestion
  var cursorRequest: TextFieldCursorRequest? = nil
  /// The text and cursor (nil when there's a selection) as they're edited, and whether the text changed
  var onEdit: (String, Int?, Bool) -> Void = { _, _, _ in }
  /// Returns true when the key was handled
  var onCommand: (Command) -> Bool = { _ in false }
  var onEndEditing: () -> Void = {}
  
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
    context.coordinator.textField = textField
    return textField
  }
  
  func updateNSView(_ nsView: NSTextField, context: Context) {
    let coordinator = context.coordinator
    coordinator.parent = self
    coordinator.isApplyingUpdate = true
    defer { coordinator.isApplyingUpdate = false }
    
    if nsView.stringValue != text {
      nsView.stringValue = text
    }
    
    if let request = cursorRequest, request.id != coordinator.appliedCursorRequest {
      coordinator.appliedCursorRequest = request.id
      if nsView.currentEditor() == nil {
        nsView.window?.makeFirstResponder(nsView)
      }
      if let editor = nsView.currentEditor() {
        let location = min(request.location, (editor.string as NSString).length)
        editor.selectedRange = NSRange(location: location, length: 0)
      }
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
