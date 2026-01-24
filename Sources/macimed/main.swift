import Foundation
import MacIMEKit

let args: [String] = ArgsCommon.getCmdArgs()
try ArgsDaemon.parse(args)

do {
   Sock.log("macimed \(Config.version) starting...")
   try Sock.startDaemon()
} catch let e as AppError {
   Sock.log(e.message)
} catch {
   Sock.log("Unexpected error\n")
}
