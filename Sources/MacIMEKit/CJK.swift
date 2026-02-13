// Note: The idea of refreshing input focus for CJK IMEs was inspired by:
//
// ims-mac (MIT licensed)
// https://github.com/LuSrackhall/ims-mac
//
// If you notice any issues with this code or the MIT License, please open an issue.

import Cocoa

enum CJK {
   /// Keep and reuse window/textField
   private static var window: NSWindow?
   private static var textField: NSTextField?

   /// Setup window
   private static func setup() {
      guard window == nil, textField == nil else { return }

      let w = NSWindow(
         contentRect: NSRect(x: 0, y: 0, width: 10, height: 10),
         styleMask: [.borderless],
         backing: .buffered,
         defer: false
      )
      w.level = .screenSaver
      w.backgroundColor = NSColor(white: 1.0, alpha: 0.5)

      let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
      tf.cell = NSSecureTextFieldCell() // password mode
      w.contentView?.addSubview(tf)

      window = w
      textField = tf
   }

   /// Refresh focus
   static func refresh() {
      // setup if no window
      if window == nil || textField == nil {
         setup()
      }

      guard let w = window, let tf = textField else { return }

      // Activate
      NSApp.activate(ignoringOtherApps: true)
      w.makeKeyAndOrderFront(nil)
      w.makeFirstResponder(tf)
      tf.becomeFirstResponder()
   }
}
