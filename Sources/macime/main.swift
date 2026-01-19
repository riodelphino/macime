import Foundation
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macime", version: "3.0.0", help: Help.macime)
public let args = ArgParser.getCmdArgs()
public let state = ArgParser.parse(args)

let response = IMECore.execute(state)

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
