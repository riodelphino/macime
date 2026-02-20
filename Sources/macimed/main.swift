import Foundation
import MacIMEKit

public var args: [String] = ArgsCommon.getCmdArgs()

do {
   let state = try ArgsIMED.parse(args)
   ArgsIMED.validate(state)
   Log.info("macimed \(Defaults.version) starting...") // DEBUG: REMOVE
   Log.debug("a test for debug log")
   Log.info("a test for info log")
   Log.warn("a test for warn log")
   Log.error("a test for error log")
   IMED.setState(state)
   DispatchQueue.global().async {
      try? IMED.serve()
   }
} catch let e as AppError {
   Log.error(e.message)
} catch {
   Log.error("Unexpected error")
}

RunLoop.main.run()
