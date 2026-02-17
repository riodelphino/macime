import Foundation
import MacIMEKit

public let args: [String] = ArgsCommon.getCmdArgs()

do {
   let state = try ArgsIME.parse(args)
   IME.setState(state)
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
