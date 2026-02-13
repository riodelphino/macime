import Foundation
import MacIMEKit

public var args: [String] = ArgsCommon.getCmdArgs()

do {
   state = try ArgsIMED.parse(args)
   Log.log("macimed \(Defaults.version) starting...")
   // try IMED.serve()
   DispatchQueue.global().async { // DEBUG: try to make daemon get/set IME ID
      try? IMED.serve()
   }
   dispatchMain()
} catch let e as AppError {
   Log.log(e.message)
} catch {
   Log.log("Unexpected error\n")
}
