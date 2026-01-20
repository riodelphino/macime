import Foundation
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macime", version: Config.version, help: Help.macime)

public let args = CmdArgs.getCmdArgs()
public let state = CmdArgs.parse(args)

let response: Response = IMECore.execute(state)

switch response.status {
case .ok:
   if response.content != "" {
      IO.out(response.content)
   }
   exit(0)
case .err:
   IO.err(response.content)
   exit(1)
}
