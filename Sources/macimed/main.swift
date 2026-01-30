import Foundation
import MacIMEKit

public var args: [String] = ArgsCommon.getCmdArgs()

do {
   state = try ArgsIMED.parse(args)
   Log.log("macimed \(Config.version) starting...")
   try IMED.serve()
} catch let e as AppError {
   Log.log(e.message)
} catch {
   Log.log("Unexpected error\n")
}
