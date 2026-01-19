import Foundation

// Arguments
public enum ArgParser {
   public static func parse() -> CmdState {
      let args = Array(CommandLine.arguments.dropFirst())
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
                  IO.err("Usage: 'macime set <IME_ID> [options]'")
                  exit(1)
               }
               i += 1
               continue
            case "get", "list", "save", "load":
               state.subcmd = arg
               i += 1
               continue
            case "--version", "-v":
               IO.out(config.version)
               exit(0)
            case "--help", "-h":
               IO.out(Help.macime)
               exit(0)
            default:
               IO.err("Usage: 'macime set|get|list|save|load [options]'")
               exit(1)
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
                  IO.err("Usage: 'macime set|load --session-id <session_id>'")
                  exit(1)
               }
            default:
               IO.err("Invalid option: \(arg)")
               exit(1)
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
