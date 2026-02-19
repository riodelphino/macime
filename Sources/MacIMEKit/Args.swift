import Foundation
import InputMethodKit

/// Arguments
public enum ArgsCommon {
   /// Get command-line args as String array
   public static func getCmdArgs() -> [String] {
      return Array(CommandLine.arguments.dropFirst())
   }

   /// Split command with args to String array
   public static func splitArgs(_ cmd: String) -> [String] {
      let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.split(separator: " ").map(String.init)
   }
}

/// macime
public enum ArgsIME {
   static let validSubcmds = ["get", "set", "load", "save", "list"]
   static let validOpts = [
      "get": ["--detail"],
      "set": ["--save", "--session-id", "--cjk-refresh"],
      "load": ["--session-id", "--cjk-refresh"],
      "save": ["--session-id"],
      "list": ["--select-capable", "--detail"],
   ]
   static let globalOpts: [String] = ["--debug", "--launchd"] // TODO: (Backward compatibility) Remove "--launchd" in later version

   private static func isValidSubcmd(_ subcmd: String) -> Bool {
      return validSubcmds.contains(subcmd)
   }

   private static func isOption(_ value: String) -> Bool {
      return value.hasPrefix("-")
   }

   private static func isValidOption(_ subcmd: String, _ value: String) -> Bool {
      return globalOpts.contains(value) || (validOpts[subcmd]?.contains(value) ?? false)
   }

   private static func fallback(_ args: [String]) -> [String] {
      var args = args
      // Fallbacks to `get` or `set` (Compatibility for `im-select`-like command usage)
      if args.isEmpty { // Fallback to `get` if zero args
         args.insert("get", at: 0)
      } else {
         if let first = args.first {
            if !isValidSubcmd(first) { // If invalid sub-command
               if isValidOption("get", first) { // Fallback to `get` if first is capable option for `get`
                  args.insert("get", at: 0)
               } else {
                  // Fallback to `set` if first is valid IME ID
                  let sources: [TISInputSource] = IME.sources(selectCapable: true)
                  let validImeIDs = Set(sources.map(\.id))
                  if validImeIDs.contains(first) {
                     args.insert("set", at: 0)
                  }
               }
            }
         }
      }
      return args
   }

   /// Parse args array into CmdState
   public static func parse(_ args: [String]) throws -> IMEState {
      let args: [String] = fallback(args)
      var state = IMEState()

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
               !isValidSubcmd(second), // IME ID must not be a valid subcmd
               !isOption(second) // IME ID must not start with `-` (option-like value)
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
         guard isValidOption(subcmd, arg) else {
            throw AppError.cmd(.unknownOptionForSubcmd(subcmd, arg))
         }
         switch arg {
         case "--detail":
            state.detail = true
         case "--select-capable":
            state.selectCapable = true
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
         case "--launchd": // TODO: (Backward compatibility) Remove in later version
            IO.err("`--launchd` option is deprecated in macime v3.6.0")
         case "--cjk-refresh":
            state.cjkRefresh = true
         case "--debug":
            state.debug = true
         default:
            throw AppError.cmd(.invalidOption(arg))
         }
         i += 1
      }
      return state
   }
}

/// macimed (daemon)
public enum ArgsIMED {
   /// Check args
   public static func parse(_ args: [String]) throws -> IMEDState {
      let state = try IMEDState()
      // Check the first arg
      if let arg = args.first {
         switch arg {
         case "--version", "-v":
            IO.out(Defaults.version)
            exit(0)
         case "--help", "-h":
            IO.out(Help.macimed)
            exit(0)
         case "--log-level", "-l":
            guard args.count >= 2 else {
               // throw AppError.imed(.missingLogLevel)
               IO.err("Missing log level.")
               exit(1)
            }
            let level: LogLevel = Log.getLogLevelByString(args[1])
            Runtime.logLevel = level
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
