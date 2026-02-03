import Foundation

public enum Defaults {
   public static let version: String = "3.3.4"

   public static var macimePath: String {
      let env = ProcessInfo.processInfo.environment
      let checkPaths = [env["MACIME_PATH"], "/usr/local/bin/macime", "/opt/homebrew/bin/macime"]
      let path = Util.fallbackPaths(checkPathExists: true, paths: checkPaths)
      guard let path else { return "" } // TODO: Should throw an Error
      return path
   }

   public static var sockPath: String {
      let env = ProcessInfo.processInfo.environment
      let checkPaths = [env["MACIME_SOCK_PATH"], "/tmp/riodelphino.macimed.sock"]
      let path = Util.fallbackPaths(checkPathExists: false, paths: checkPaths)
      guard let path else { return "" } // TODO: Should throw an Error
      return path
   }

   public static var tempDir: String {
      let env = ProcessInfo.processInfo.environment
      let checkPaths = [env["MACIME_TEMP_DIR"], "/tmp/riodelphino.macime"]
      let path = Util.fallbackPaths(checkPathExists: false, paths: checkPaths)
      guard let path else { return "" } // TODO: Should throw an Error
      return path
   }
}

/// Keeps commmand line args
public struct IMECmdState {
   public var subcmd: String?
   public var save: Bool = false
   public var newID: String?
   public var selectCapable: Bool = false
   public var detail: Bool = false
   public var sessionID: String?
   public var launchd: Bool = false
   public init() {}
}

public struct IMEDCmdState {
   public var macimePath: String?
   public var sockPath: String?
   public var status: String?
   public var logPath: String?
   public var errPath: String?
   public init() {
      macimePath = Defaults.macimePath
      sockPath = Defaults.sockPath
      status = IMED.isMacimedRunning(sockPath: Defaults.sockPath) ? "running" : "stopped"
   }
}

public enum OutFormat {
   case text
   case json
}

public enum Colors {
   case red
   case blue
   case green
   case yellow
   case reset
   public var color: String {
      switch self {
      case .red:
         return "\u{001B}[31m"
      case .green:
         return "\u{001B}[32m"
      case .yellow:
         return "\u{001B}[33m"
      case .blue:
         return "\u{001B}[34m"
      case .reset:
         return "\u{001B}[0m"
      }
   }
}

public enum Help {
   public static let macime = """
   Usage: macime <sub_command> [<options>]

   Sub commands:
      get     Get current IME
      set     Set IME
      save    Save IME
      load    Restore IME
      list    List IMEs

   Get current IME
      macime get [--detail] [--launchd]

   Set IME 
      macime set <IME_id> [--save] [--session-id <session_id>] [--launchd]

      Set IME only (no save)
         macime set <IME_id>
      
      Set IME while saving current IME to `DEFAULT` file in temp dir
         macime set <IME_id> --save
      
      Set IME while saving current IME to `<session_id>` file in temp dir
         macime set <IME_id> --save --session-id <session_id>

   Save IME
      macime save [--session-id <session_id>] [--launchd]

      Save current IME to `DEFAULT` file in temp dir
         macime save

      Save current IME to `<session_id>` file in temp dir
         macime save --session-id <session_id>

   Load (restore) IME
      macime load [--session-id <session_id>] [--launchd]

      Load previouse IME from `DEFAULT` file in temp dir
         macime load

      Load previous IME from `<session_id>` file in temp dir
         macime load --session-id <session_id>

   List IMEs
      macime list [--detail] [--select-capable] [--launchd]


   OPTIONS:
      --help, -h
         Show help

      --version, -v
         Show version

      --detail
         Show detailed IME info as JSON
         
      --select-capable
         Show only selectable IME

      --save
         Save current IME

      --session-id <session_id>
         Specify the save filename

      --launchd
         Indicate the command is called via launchd
   """
   public static let macimed = """
   Usage: macimed [options]

   A daemon tool that wraps `macime` command for launchd service.

   To start service via Homebrew (Faster):
      brew services start macime 

   To start service manually for debugging (Slower):
      macimed

   OPTIONS:

      --help, -h
         Show help

      --version, -v
         Show version


   """
}
