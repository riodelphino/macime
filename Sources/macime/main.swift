import Foundation
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macime", version: Config.version, help: Help.macime)

public let args: [String] = ArgsCommon.getCmdArgs()
public var state: CmdState = CmdState()

do {
   state = try ArgsMacIME.parse(args)
   let ret: String = try IMECore.execute(state)
   IO.out(ret)
   exit(0)
} catch let e as AppError {
   let prefix = state.launchd == true ? "" : Util.colored(.red, "[ERROR] ")
   IO.err(prefix + e.message)
} catch {
   let prefix = state.launchd == true ? "" : Util.colored(.red, "[ERROR] ")
   IO.err(prefix + "Unexpected error\n")
   exit(1)
}
