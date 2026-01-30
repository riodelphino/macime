import Foundation

// Arguments
public enum ArgsCommon {

   // Get command-line args as String array
   public static func getCmdArgs() -> [String] {
      return Array(CommandLine.arguments.dropFirst())
   }

   // Split command with args to String array
   public static func splitArgs(_ cmd: String) -> [String] {
      let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
      let parts = trimmed.split(separator: " ").map(String.init)
      return parts
   }
}

// macime
public enum ArgsIME {
   static let capableSubcmd = ["get", "set", "load", "save", "list"]
   static let capableOpts = [
      "get": ["--detail", "--json"],
      "set": ["--save", "--session-id"],
      "load": ["--session-id"],
      "save": ["--session-id"],
      "list": ["--select-capable", "--detail", "--json"],
   ]
   static let globalOpts = ["--launchd"]

   public static func isOption(_ value: String) -> Bool {
      return value.hasPrefix("-")
   }

   public static func isCapableOption(_ subcmd: String, _ value: String) -> Bool {
      return globalOpts.contains(value) || (capableOpts[subcmd]?.contains(value) ?? false)
   }

   // Parse args array into CmdState
   public static func parse(_ args: [String]) throws -> IMECmdState {
      var args: [String] = args
      var state = IMECmdState()

      // Fallbacks to `get` or `set`
      if let first = args.first {
         let isSubcmd = capableSubcmd.contains(first)
         if !isSubcmd {  // If not sub command
            if isCapableOption("get", first) {
               args.insert("get", at: 0)  // Fallback to `get`
            } else if !isOption(first) {
               args.insert("set", at: 0)  // Fallback to `set`
            }
         }
      } else {
         // Fallback to `get` if zero args
         args.insert("get", at: 0)
      }

      // Parse the first arg
      var index = 0
      if let first = args.first {
         switch first {
         case "set":
            state.subcmd = "set"
            guard args.count >= 2 else {
               throw AppError.cmd(.setMissingID)
            }
            let second = args[1]
            guard
               !capableSubcmd.contains(second),  // IME ID must not be a valid subcmd
               !isOption(second)  // IME ID must not start with `-` (option-like value)
            else {
               throw AppError.cmd(.setMissingID)
            }
            state.newID = second
            index += 2
         case "get", "list", "save", "load":
            state.subcmd = first
            index += 1
         case "--version", "-v":
            IO.out(Defaults.version)
            exit(0)
         case "--help", "-h":
            IO.out(Help.macime)
            exit(0)
         default:
            throw AppError.cmd(.invalidSubCommand(first))
         }
      }

      guard let subcmd = state.subcmd else {
         throw AppError.cmd(.subcmdNotFound)
      }

      // Parse other args
      var i = index
      while i < args.count {
         let arg = args[i]
         guard isOption(arg) else {
            throw AppError.cmd(.invalidOption(arg))
         }
         guard isCapableOption(subcmd, arg) else {
            throw AppError.cmd(.unknownOptionForSubcmd(subcmd, arg))
         }
         switch arg {
         case "--detail":
            state.detail = true
         case "--select-capable":
            state.selectCapable = true
         case "--json":
            state.json = true
         case "--save":
            state.save = true
         case "--session-id":
            // TODO: Should check `set xxx --session-id xxx` has `--save` option togerther
            guard i + 1 < args.count else {
               throw AppError.cmd(.missingSessionID)
            }
            let next = args[i + 1]
            guard !isOption(next) else {
               throw AppError.cmd(.missingSessionID)
            }
            state.sessionID = next
            i += 1
         case "--launchd":
            state.launchd = true
         default:
            throw AppError.cmd(.invalidOption(arg))
         }
         i += 1
      }
      return state
   }
}

// macimed (daemon)
public enum ArgsIMED {
   // Check args
   public static func parse(_ args: [String]) throws -> IMEDCmdState {
      let state = IMEDCmdState()
      // Check the first arg
      if let arg = args.first {
         switch arg {
         case "--version", "-v":
            IO.out(Defaults.version)
            exit(0)
         case "--help", "-h":
            IO.out(Help.macimed)
            exit(0)
         case "--status", "-s":
            if state.status == "running" {
               IO.out("running")
               exit(0)
            } else {
               IO.out("stopped")
               exit(1)
            }
         case "--info", "-i":
            var info: [String] = []
            info.append("sockPath   : \(state.sockPath ?? "")")
            info.append("status     : \(state.status ?? "")")
            info.append("macimePath : \(state.macimePath ?? "")")  // Does not reflect running macimed's macimePath when executed by `MACIME_PATH=xxx macimed`
            IO.out(info.joined(separator: "\n"))
            exit(0)
         default:
            IO.err("Unknown Option: \(arg)")
            exit(1)
         }
      }
      guard FS.pathExists(state.macimePath ?? "") else {
         throw AppError.imed(.macimeNotFound(state.macimePath ?? ""))
      }

      return state
   }
}
