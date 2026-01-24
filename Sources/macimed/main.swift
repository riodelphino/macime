import Foundation
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macimed", version: Config.version, help: Help.macimed)

do {
   Sock.log("macimed \(cmdSpec.version) starting...")
   try Sock.startDaemon()
} catch let e as AppError {
   Sock.log(e.message)
} catch {
   Sock.log("Unexpected error\n")
}
