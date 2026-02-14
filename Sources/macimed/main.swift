import Cocoa
import Foundation
import MacIMEKit

public var args: [String] = ArgsCommon.getCmdArgs()

let app = NSApplication.shared
NSApp.setActivationPolicy(.accessory)

class AppDelegate: NSObject, NSApplicationDelegate {
   func applicationDidFinishLaunching(_: Notification) {
      do {
         state = try ArgsIMED.parse(args)
         Log.log("macimed \(Defaults.version) starting...")

         DispatchQueue.global().async {
            try? IMED.serve()
         }

      } catch let e as AppError {
         Log.log(e.message)
      } catch {
         Log.log("Unexpected error")
      }
   }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()
