import Foundation
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macimed", version: "3.0.2", help: Help.macimed)

do {
   Sock.log("macimed \(cmdSpec.version) starting...")
   try Sock.startDaemon()
} catch {
   Sock.log("ERROR: \(error)")
   exit(1)
}
