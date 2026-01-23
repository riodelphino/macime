import Foundation

// Arguments
public enum CmdArgs {

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

   // Parse args array into CmdState
   public static func parse(_ args: [String]) throws -> CmdState {
      var state = CmdState()

      // Parse args
      var i = 0
      while i < args.count {
         let arg = args[i]
         if i == 0 {
            switch arg {
            case "set":
               state.subcmd = "set"
               if i + 1 < args.count {
                  state.newID = args[i + 1]
                  i += 1
               } else {
                  throw CmdError.setMissingID
               }
               i += 1
               continue
            case "get", "list", "save", "load":
               state.subcmd = arg
               i += 1
               continue
            case "--version", "-v":  // TODO: It's too special. Only return CmdState, so can't return `version` with String...
               IO.out(Config.version)
               exit(0)
            case "--help", "-h":  // TODO: Same above
               IO.out(Help.macime)  // TODO: Is it fixed to macime? -> Also supports macimed!
               exit(0)
            default:
               throw CmdError.invalidSubCommand(arg)
            }
         }

         if arg.hasPrefix("--") {
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
               if i + 1 < args.count {
                  state.sessionID = args[i + 1]
                  i += 1
               } else {
                  throw CmdError.missingSessionID
               }
            default:
               throw CmdError.invalidOption(arg)

            }
         } else {
            state.newID = arg  // IME method ID
         }
         i += 1
      }

      // Prioritize `list` sub command
      if state.subcmd == "list" {
         state.newID = nil
      }

      // Ommit `--save` option in `save` sub command
      if state.subcmd == "save" {
         state.save = false
      }

      // dump(opts, name: "opts")  // for debug

      return state
   }
}
