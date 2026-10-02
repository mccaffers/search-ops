// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(macOS)
import AppKit

/// Plain monospaced text editor for typing requests.
/// Smart quotes, dashes & autocorrect are disabled as they silently break JSON
struct macosCodeEditor: NSViewRepresentable {
  @Binding var text: String
  var fontSize: CGFloat = 13

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSTextView.scrollableTextView()
    scrollView.drawsBackground = false
    scrollView.autohidesScrollers = true

    guard let textView = scrollView.documentView as? NSTextView else {
      return scrollView
    }

    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    textView.delegate = context.coordinator
    textView.isEditable = true
    textView.isSelectable = true
    textView.isRichText = false
    textView.allowsUndo = true
    textView.drawsBackground = false
    textView.font = font
    textView.textColor = NSColor.textColor
    textView.insertionPointColor = NSColor.textColor
    textView.typingAttributes = [.font: font, .foregroundColor: NSColor.textColor]
    textView.textContainerInset = NSSize(width: 6, height: 8)

    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isAutomaticDashSubstitutionEnabled = false
    textView.isAutomaticTextReplacementEnabled = false
    textView.isAutomaticSpellingCorrectionEnabled = false
    textView.isContinuousSpellCheckingEnabled = false
    textView.isGrammarCheckingEnabled = false
    textView.isAutomaticLinkDetectionEnabled = false
    textView.isAutomaticDataDetectionEnabled = false
    textView.smartInsertDeleteEnabled = false

    textView.string = text
    return scrollView
  }

  func updateNSView(_ nsView: NSScrollView, context: Context) {
    context.coordinator.parent = self
    guard let textView = nsView.documentView as? NSTextView else { return }
    // Only replace the text when it changed externally, otherwise the cursor jumps
    if textView.string != text {
      textView.string = text
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, NSTextViewDelegate {
    var parent: macosCodeEditor

    init(_ parent: macosCodeEditor) {
      self.parent = parent
    }

    func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }
      parent.text = textView.string
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
      // Carry the current line's indentation onto the new line
      guard commandSelector == #selector(NSResponder.insertNewline(_:)) else {
        return false
      }

      let content = textView.string as NSString
      let cursor = textView.selectedRange().location
      let lineRange = content.lineRange(for: NSRange(location: cursor, length: 0))
      let line = content.substring(with: NSRange(location: lineRange.location,
                                                 length: cursor - lineRange.location))
      let indentation = line.prefix(while: { $0 == " " || $0 == "\t" })

      textView.insertText("\n" + indentation, replacementRange: textView.selectedRange())
      return true
    }
  }
}
#endif
