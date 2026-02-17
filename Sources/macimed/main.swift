import Foundation
import MacIMEKit

public var args: [String] = ArgsCommon.getCmdArgs()

do {
   Log.log("macimed \(Defaults.version) starting...")
   let state = try ArgsIMED.parse(args)
   IMED.setState(state)
   DispatchQueue.global().async {
      try? IMED.serve()
   }
} catch let e as AppError {
   Log.log(e.message)
} catch {
   Log.log("Unexpected error")
}

RunLoop.main.run()
