import Foundation
import MacIMEKit

public let args: [String] = ArgsCommon.getCmdArgs()
public var state = IMECmdState()

do {
   state = try ArgsIME.parse(args)
   let ret: String = try IME.execute(state)
   if ret != "" {
      IO.out(ret)
   }
   exit(0)
} catch let e as AppError {
   IO.err(e.message)
} catch {
   IO.err("Unexpected error\n")
   exit(1)
}
