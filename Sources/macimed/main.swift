import Foundation
import MacIMEKit

let args: [String] = ArgsCommon.getCmdArgs()
try ArgsIMED.parse(args)

do {
   IMED.log("macimed \(Config.version) starting...")
   try IMED.startDaemon()
} catch let e as AppError {
   IMED.log(e.message)
} catch {
   IMED.log("Unexpected error\n")
}
