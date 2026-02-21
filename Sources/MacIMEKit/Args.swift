import Foundation
import InputMethodKit

/// [Common] Args
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

/// [IME] Args
public enum IMEArgs {
   private static func isValidSubcmd(_ subcmd: String) -> Bool {
      return IMESubCmd(rawValue: subcmd) != nil
   }

   private static func isOption(_ value: String) -> Bool {
      return value.hasPrefix("-")
   }

   private static func isValidOption(_ subcmd: IMESubCmd, _ option: String) -> Bool {
      guard
         let opt = IMEOption(rawValue: option)
      else {
         return false
      }
      return subcmd.validOptions.contains(opt)
   }

   private static func fallback(_ args: [String]) -> [String] {
      var args = args
      // Fallbacks to `get` or `set` (Compatibility for `im-select`-like command usage)
      if args.isEmpty { // Fallback to `get` if zero args
         args.insert("get", at: 0)
      } else {
         if let first = args.first {
            if !isValidSubcmd(first) { // If invalid sub-command
               if isValidOption(IMESubCmd(rawValue: "get")!, first) { // Fallback to `get` if first is capable option for `get`
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
      var args: [String] = fallback(args)
      var state = IMEState()

      // Parse help and version
      if let first = args.first {
         switch first {
         case "--version", "-v":
            IO.out(Defaults.version)
            exit(0)
         case "--help", "-h":
            IO.out(Help.macime)
            exit(0)
         default:
            break
         }
      }

      // Parse the first arg
      let subcmdStr = args.removeFirst()
      guard let subcmd = IMESubCmd(rawValue: subcmdStr) else {
         throw AppError.cmd(.invalidSubCommand(subcmdStr))
      }

      switch subcmd {
      case .set:
         state.subcmd = subcmd
         guard args.count > 0 else {
            throw AppError.cmd(.missingRequiredValue("set", "IME ID"))
         }
         state.newID = args.removeFirst()
      case .get, .list, .save, .load:
         state.subcmd = subcmd
      }

      // Parse other args
      var i = 0
      while i < args.count {
         let arg = args[i]
         guard isOption(arg) else {
            throw AppError.cmd(.invalidOption(arg))
         }
         guard isValidOption(subcmd, arg) else {
            throw AppError.cmd(.invalidOptionForSubcmd(subcmd.rawValue, arg))
         }
         let opt = IMEOption(rawValue: arg)
         switch opt {
         case .detail:
            state.detail = true
         case .selectCapable:
            state.selectCapable = true
         case .save:
            state.save = true
         case .sessionID:
            guard i + 1 < args.count else {
               throw AppError.cmd(.missingRequiredValue("--sessiond-id", "Session ID"))
            }
            let sessionID = args[i + 1]
            state.sessionID = sessionID
            i += 1
         case .launchd: // TODO: (Backward compatibility) Remove in later version
            IO.err("'--launchd' option is deprecated in macime v3.6.0")
         case .cjkRefresh:
            state.cjkRefresh = true
         case .cjkDelay:
            guard i + 1 < args.count else {
               throw AppError.cmd(.missingCjkDelay)
            }
            guard let delay = Double(args[i + 1]) else {
               throw AppError.cmd(.invalidCjkDelay(args[i + 1]))
            }
            guard delay >= 0 && delay <= 1 else {
               throw AppError.cmd(.invalidCjkDelay(args[i + 1]))
            }
            state.cjkDelay = delay
            i += 1
         case .debug:
            state.debug = true
         default:
            throw AppError.cmd(.invalidOption(arg))
         }
         i += 1
      }
      return state
   }

   public static func validate(_ state: IMEState) throws {
      if
         state.subcmd != .save,
         let sessionID = state.sessionID
      {
         guard state.save else { // `sessionID` requires `--save` togather
            throw AppError.cmd(.missingRequiredOption("--session-id", "--save"))
         }
         guard !isOption(sessionID) else { // `sessionID` must not be an option-like value `--xxx`
            throw AppError.cmd(.missingRequiredValue("--session-id", "Session ID"))
         }
      }
      if let newID = state.newID {
         guard
            !isValidSubcmd(newID), // IME ID must not be a valid subcmd
            !isOption(newID) // IME ID must not start with `-` (option-like value)
         else {
            throw AppError.cmd(.invalidImeId(newID))
         }
      }
      if let _ = state.cjkDelay {
         if !state.cjkRefresh { throw AppError.cmd(.missingRequiredOption("--cjk-delay", "--cjk-refresh")) }
      }
   }
}

/// [IMED] Args
public enum IMEDArgs {
   /// Parse command-line args
   public static func parse(_ args: [String]) throws -> IMEDState {
      let state = try IMEDState()
      // Check the args
      var i = 0
      while i < args.count {
         let arg = args[i]
         switch arg {
         case "--version", "-v":
            IO.out(Defaults.version)
            exit(0)
         case "--help", "-h":
            IO.out(Help.macimed)
            exit(0)
         case "--log-level", "-l":
            guard args.count > i + 1 else {
               // throw AppError.imed(.missingLogLevel)
               IO.err("Missing log level. Use: debug|info|warn|error")
               exit(1)
            }
            guard let level = LogLevel(args[i + 1]) else {
               IO.err("Invalid log level: \(args[i + 1]). Use: debug|info|warn|error")
               exit(1)
            }
            Runtime.logLevel = level
            i += 1
         default:
            IO.err("Unknown Option: \(arg)")
            exit(1)
         }
         i += 1
      }
      guard FS.pathExists(state.macimePath ?? "") else {
         throw AppError.imed(.macimeNotFound(state.macimePath ?? ""))
      }

      return state
   }

   /// Validate IMEDState
   public static func validate(_: IMEDState) {
      // Add validations in future
   }
}
