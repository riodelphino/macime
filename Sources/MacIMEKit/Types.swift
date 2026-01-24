import Foundation

public struct Config {
   public static var version: String = "3.0.5"
   public static var tempDir: String = "/tmp/riodelphino.macime"
   public static var sockPath: String = "/tmp/riodelphino.macimed.sock"
   public static var macimePath: String = "/usr/local/bin/macime"
   public init() {}
}

public enum AppError: Error {
   case cmd(CmdError)
   case util(UtilError)
   case ime(IMEError)
   case sock(SockError)

   public var message: String {
      switch self {
      case .cmd(let e):
         return e.message
      case .util(let e):
         return e.message
      case .ime(let e):
         return e.message
      case .sock(let e):
         return e.message
      }
   }
}

public enum CmdError: Error {
   case setMissingID
   case invalidSubCommand(String)
   case missingSessionID
   case invalidOption(String)

   public var message: String {
      switch self {
      case .setMissingID:
         return "`set` sub command requires IME ID."
      case .invalidSubCommand(let subcmd):
         return "Invalid sub command: \(subcmd)"
      case .missingSessionID:
         return "`--session-id` option requires session ID."
      case .invalidOption(let option):
         return "Unknown option: \(option)"
      }
   }
}

public enum UtilError: Error {
   case invalidJsonFormat

   public var message: String {
      switch self {
      case .invalidJsonFormat:
         return "Invalid JSON format."
      }
   }
}

public enum SockError: Error {
   case dataNotRecieved

   public var message: String {
      switch self {
      case .dataNotRecieved:
         return "Data was not recieved."
      }
   }
}

public enum IMEError: Error {
   case notFound(String)
   case selectFailed(String, OSStatus)
   case getCurrentFailed
   case getPreviousFailed(String)  // unused ?
   case previousIDNotFound
   case createDirFailed(String)
   case saveFailed(String)
   case loadFailed(String)
   case jsonSerializationFailed(String)
   case invalidSubCommand(String)

   public var message: String {
      switch self {
      case .notFound(let id):
         return "IME not found: \(id)"
      case .selectFailed(let id, let osstatus):
         return "Select failed: \(id) / \(osstatus)"
      case .getCurrentFailed:
         return "Get current failed."
      case .getPreviousFailed(let id):
         return "Get previous failed: \(id)"
      case .previousIDNotFound:
         return "Previous ID not found."
      case .createDirFailed(let dir):
         return "Create dir failed: \(dir)"
      case .saveFailed(let path):
         return "Save failed to: \(path)"
      case .loadFailed(let path):
         return "Load failed from: \(path)"
      case .jsonSerializationFailed(let msg):
         return "Json serializention failed: \(msg)"
      case .invalidSubCommand(let subcmd):
         return "Invalid sub command: \(subcmd)"
      }
   }
}

public struct CmdSpec {
   public let name: String  // macime|macimed
   public let version: String
   public let help: String
   public init(name: String, version: String, help: String) {
      self.name = name
      self.version = version
      self.help = help
   }
}

// Keeps commmand line args
public struct CmdState {
   public var subcmd: String? = nil
   public var save: Bool = false
   public var newID: String? = nil
   public var selectCapable: Bool = false
   public var detail: Bool = false
   public var json = false
   public var sessionID: String? = nil
   public init() {}
}

public enum OutFormat {
   case value
   case keyValue
   case json
}

public enum ResponseStatus {
   case ok, err
}
public struct Response {
   public var status: ResponseStatus
   public var content: String
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
         macime get [--detail] [--json]

      Set IME 
         macime set <IME_id> [--save] [--session-id <session_id>]

         Set IME only (no save)
            macime set <IME_id>
         
         Set IME while saving current IME to `DEFAULT` file in temp dir
            macime set <IME_id> --save
         
         Set IME while saving current IME to `<session_id>` file in temp dir
            macime set <IME_id> --save --session-id <session_id>

      Save IME
         macime save [--session-id <session_id>]

         Save current IME to `DEFAULT` file in temp dir
            macime save

         Save current IME to `<session_id>` file in temp dir
            macime save --session-id <session_id>

      Load (restore) IME
         macime load [--session-id <session_id>]

         Load previouse IME from `DEFAULT` file in temp dir
            macime load

         Load previous IME from `<session_id>` file in temp dir
            macime load --session-id <session_id>

      List IMEs
         macime list [--detail] [--select-capable] [--json]


      OPTIONS:

         --detail
            Show detailed IME info
            
         --select-capable
            Show only selectable IME

         --json
            Output as json

         --save
            Save current IME

         --session-id <session_id>
            Specify the save filename

      """
   public static let macimed = """
      Usage: macimed

      This is a daemon tool that wraps `macime` command for launchd service.

      Start service with brew
        brew services start macime 

      Start service manually
         launchctl load ~/Library/LaunchAgents/com.riodelphino.macimed.plist
      """
}
