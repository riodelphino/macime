import Foundation
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macime", version: Config.version, help: Help.macime)

public let args: [String] = CmdArgs.getCmdArgs()
public var state: CmdState

do {
   state = try CmdArgs.parse(args)
   let ret: String = try IMECore.execute(state)
   IO.out(ret)
   exit(0)
} catch let e as AppError {
   IO.err(e.message)
} catch let e as IMEError {
   IO.err(e.message)
} catch let e as CmdError {
   IO.err(e.message)
} catch {
   IO.err("Unexpected error\n")
   exit(1)
}
