import Foundation
import MacIMEKit

public var args: [String] = ArgsCommon.getCmdArgs()

do {
   let state = try ArgsIMED.parse(args)
   Log.info("macimed \(Defaults.version) starting...")
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
