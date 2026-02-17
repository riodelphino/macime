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
   private static var inputSourceObserver: NSObjectProtocol?
   private static var start: CFAbsoluteTime = 0
   private static var timeout: CFTimeInterval = 0.2

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

      let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 1, height: 1))

      tf.font = NSFont.systemFont(ofSize: 13)
      tf.bezelStyle = .roundedBezel
      tf.isEditable = true
      tf.isSelectable = true
      tf.cell = NSSecureTextFieldCell()

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

   private static func checkIMEChanged(desiredID: String) {
      guard
         let current = try? IME.current(),
         let w = window
      else {
         return
      }
      if current.id == desiredID || CFAbsoluteTimeGetCurrent() - start > timeout {
         w.orderOut(nil)
         if let observer = inputSourceObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            inputSourceObserver = nil
         }
         // if current.id != desiredID { // TODO: REMOVE: Doesn't contribute switching success rate
         //    _ = try? IME.select(id: desiredID) // Ensure to select desiredID again
         // }
         return
      } else {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
            checkIMEChanged(desiredID: desiredID)
         }
      }
   }

   static func refresh(desiredID: String) {
      guard Thread.isMainThread else {
         DispatchQueue.main.async { CJK.refresh(desiredID: desiredID) }
         return
      }

      _ = NSApplication.shared
      NSApp.setActivationPolicy(.accessory)

      if window == nil { setup() }

      guard let w = window, let tf = textField else { return }

      w.orderFront(nil)
      w.makeKey()
      w.makeFirstResponder(tf)

      // Hide window (async/simple ver)
      // DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // 0.05 is Environment-dependent value
      //    w.orderOut(nil)
      // }

      // Hide window (async/wait for switching)
      if let observer = inputSourceObserver {
         DistributedNotificationCenter.default().removeObserver(observer)
         inputSourceObserver = nil
      }
      inputSourceObserver = DistributedNotificationCenter.default().addObserver(
         forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
         object: nil,
         queue: .main
      ) { _ in
         start = CFAbsoluteTimeGetCurrent()
         checkIMEChanged(desiredID: desiredID)
      }
   }
}
