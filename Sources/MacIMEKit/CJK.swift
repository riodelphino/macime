// Portions of this file are derived from refresh-input-focus.swift
// in ims-mac:
// https://github.com/LuSrackhall/ims-mac
//
// Copyright (c) 2025 LuSrackhall
// Licensed under the MIT License.
//
// Modifications have been made.

import Carbon
import Cocoa

enum CJK {
   private static var window: NSWindow?
   private static var textField: NSTextField?
   private static var delegate: NSObject?
   private static let defaultCjkDelay: Double = 0.05 // TODO: Doesn't seem to contribute success rate

   private static func setup() {
      guard window == nil else { return }

      let w = NSWindow(
         contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
         // styleMask: [.borderless, .nonactivatingPanel],
         styleMask: [.borderless],
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

      Log.debug("Initialized CJK temp window")

      let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 1, height: 1))

      tf.font = NSFont.systemFont(ofSize: 13)
      tf.bezelStyle = .roundedBezel
      tf.isEditable = true
      tf.isSelectable = true
      tf.cell = NSSecureTextFieldCell()

      Log.debug("Initialized CJK temp textField")

      // TODO: REMOVE (Does not seem to contribute to switching success rate)
      // class TextFieldDelegate: NSObject, NSTextFieldDelegate {
      //    func controlTextDidChange(_ obj: Notification) {
      //       _ = (obj.object as? NSTextField)?.stringValue
      //    }
      //
      //    func control(
      //       _: NSControl,
      //       textView _: NSTextView,
      //       doCommandBy commandSelector: Selector
      //    ) -> Bool {
      //       if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
      //          return true
      //       }
      //       return false
      //    }
      // }
      //
      // let d = TextFieldDelegate()
      // tf.delegate = d

      w.contentView?.addSubview(effectView)
      w.contentView?.addSubview(tf)

      w.initialFirstResponder = tf
      w.setFrameOrigin(NSPoint(x: 0, y: 0))

      window = w
      textField = tf
      // delegate = d
   }

   static func refresh(desiredID: String, cjkDelay: Double?) {
      guard Thread.isMainThread else {
         Log.debug("Recall CJK.refresh() asynchronously")
         DispatchQueue.main.async { refresh(desiredID: desiredID, cjkDelay: cjkDelay) }

         return
      }
      Log.debug("CJK.refresh() started")
      Log.debug("CJK delay: \(String(cjkDelay ?? defaultCjkDelay))")

      _ = NSApplication.shared
      NSApp.setActivationPolicy(.accessory)

      if window == nil { setup() }

      guard let w = window, let tf = textField else { return }

      w.orderFront(nil)
      w.makeKey()
      w.makeFirstResponder(tf)
      Log.debug("Activated CJK temp window.")

      // Hide window (async/simple ver)
      DispatchQueue.main.asyncAfter(deadline: .now() + defaultCjkDelay) {
         w.orderOut(nil)
         Log.debug("Deactivated CJK temp window.")
      }
   }
}
