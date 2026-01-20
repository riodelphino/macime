import Foundation
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macimed", version: config.version, help: Help.macimed)

do {
   Sock.log("macimed \(cmdSpec.version) starting...")
   try Sock.startDaemon()
} catch {
   Sock.log("ERROR: \(error)")
   exit(1)
}
