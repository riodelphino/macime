// Note: The idea and code for refreshing input focus for CJK IMEs are from:
//
// ims-mac (MIT licensed)
// https://github.com/LuSrackhall/ims-mac
//
// Thanks for all the effort!
//
// (If you notice any issues with this code or the MIT License, please open an issue.)

import Cocoa

enum CJK {
   private static var window: NSWindow?
   private static var textField: NSTextField?
   private static var delegate: NSObject?

   private static func setup() {
      guard window == nil else { return }

      let w = NSWindow(
         contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
         styleMask: [.borderless, .nonactivatingPanel],
         backing: .buffered,
         defer: false
      )

      w.backgroundColor = .clear
      w.hasShadow = false
      w.level = .screenSaver
      w.isOpaque = false
      w.alphaValue = 0.01

      let effectView = NSVisualEffectView(frame: w.contentView!.bounds)
      effectView.material = .popover
      effectView.state = .active

      let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 1, height: 1))

      tf.font = NSFont.systemFont(ofSize: 13)
      tf.bezelStyle = .roundedBezel
      tf.isEditable = true
      tf.isSelectable = true
      tf.cell = NSSecureTextFieldCell()

      class TextFieldDelegate: NSObject, NSTextFieldDelegate {
         func controlTextDidChange(_ obj: Notification) {
            _ = (obj.object as? NSTextField)?.stringValue
         }

         func control(
            _: NSControl,
            textView _: NSTextView,
            doCommandBy commandSelector: Selector
         ) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
               return true
            }
            return false
         }
      }

      let d = TextFieldDelegate()
      tf.delegate = d

      w.contentView?.addSubview(effectView)
      w.contentView?.addSubview(tf)

      w.initialFirstResponder = tf
      w.setFrameOrigin(NSPoint(x: 0, y: 0))

      window = w
      textField = tf
      delegate = d
   }

   static func refresh() {
      if window == nil || textField == nil {
         setup()
      }

      guard let w = window, let tf = textField else { return }

      // NSApp.activate(ignoringOtherApps: true) // Disabled because it takes focus and does not return it in daemon.
      w.makeKeyAndOrderFront(nil)
      w.makeFirstResponder(tf)

      // Run the loop once // TODO: NO NEED?
      // RunLoop.main.run(until: Date().addingTimeInterval(0.02))

      // Recieve events first
      tf.becomeFirstResponder()

      // Hide window
      w.orderOut(nil)
   }
}
