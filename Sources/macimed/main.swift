import Foundation
import MacIMEKit

let args: [String] = ArgsCommon.getCmdArgs()
try ArgsIMED.parse(args)

do {
   Log.log("macimed \(Config.version) starting...")
   try IMED.startDaemon()
} catch let e as AppError {
   Log.log(e.message)
} catch {
   Log.log("Unexpected error\n")
}
