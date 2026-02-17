import Foundation
import MacIMEKit

public var args: [String] = ArgsCommon.getCmdArgs()

do {
   let state = try ArgsIMED.parse(args)
   Log.log("macimed \(Defaults.version) starting...")
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
