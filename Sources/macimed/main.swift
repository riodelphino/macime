import Foundation
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macimed", version: Config.version, help: Help.macimed)
let args: [String] = ArgsCommon.getCmdArgs()
try ArgsDaemon.parse(args)

do {
   Sock.log("macimed \(cmdSpec.version) starting...")
   try Sock.startDaemon()
} catch let e as AppError {
   Sock.log(e.message)
} catch {
   Sock.log("Unexpected error\n")
}
