import Foundation

public enum AppError: Error {
   case config(ConfigError)
   case cmd(CmdError)
   case util(UtilError)
   case ime(IMEError)
   case imed(IMEDError)

   public var message: String {
      switch self {
      case let .config(e):
         return e.message
      case let .cmd(e):
         return e.message
      case let .util(e):
         return e.message
      case let .ime(e):
         return e.message
      case let .imed(e):
         return e.message
      }
   }
}

public enum ConfigError: Error { // TODO: Remove if unused
   case invalidMacimePath
   case invalidSockPath
   case invalidTempDir

   public var message: String {
      switch self {
      case .invalidMacimePath:
         return "Invalid macime path."
      case .invalidSockPath:
         return "Invalid sock path."
      case .invalidTempDir:
         return "Invalid temp dir."
      }
   }
}

public enum CmdError: Error {
   case setMissingID
   case invalidSubCommand(String)
   case missingSessionID
   case invalidOption(String)
   case subcmdNotFound
   case unknownOptionForSubcmd(String, String)

   public var message: String {
      switch self {
      // macime
      case .setMissingID:
         return "`set` sub command requires IME ID."
      case let .invalidSubCommand(subcmd):
         return "Invalid sub command: \(subcmd)"
      case .missingSessionID:
         return "`--session-id` option requires session ID."
      case let .invalidOption(option):
         return "Unknown option: \(option)"
      case .subcmdNotFound:
         return "Sub command not found."
      case let .unknownOptionForSubcmd(subcmd, option):
         return "Unknown option for `\(subcmd)`: \(option)"
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

public enum IMEDError: Error {
   case dataNotRecieved
   case macimeNotFound(String)
   case sockPathNotFound(String)
   case macimeReturnsError(String)
   case invalidDaemonMethod(String)
   case invalidDaemonSubcmd(String)
   case invalidGetTarget(String)
   case invalidSetTarget(String)
   case invalidPath(String)
   case notExecutable(String)

   public var message: String {
      switch self {
      case .dataNotRecieved:
         return "Data not recieved."
      case let .macimeNotFound(path):
         return "macime executable not found: \(path)"
      case let .sockPathNotFound(path):
         return "sock-path not found: \(path)"
      case let .macimeReturnsError(err):
         return "`macime` returns Error: \(err)"
      case let .invalidDaemonMethod(method):
         return "Invalid daemon method: \(method)"
      case let .invalidDaemonSubcmd(subcmd):
         return "Invalid daemon sub command: \(subcmd)"
      case let .invalidGetTarget(target):
         return "Invalid `get` target: \(target)"
      case let .invalidSetTarget(target):
         return "Invalid `set` target: \(target)"
      case let .invalidPath(path):
         return "Invalid path: \(path)"
      case let .notExecutable(path):
         return "Not executable: \(path)"
      }
   }
}

public enum IMEError: Error {
   case notFound(String)
   case selectFailed(String, OSStatus)
   case getCurrentFailed
   case getPreviousFailed(String) // unused ?
   case previousIDNotFound
   case createDirFailed(String)
   case saveFailed(String)
   case loadFailed(String)
   case jsonSerializationFailed(String)
   case invalidSubCommand(String)
   case missingTargetID

   public var message: String {
      switch self {
      case let .notFound(id):
         return "IME not found: \(id)"
      case let .selectFailed(id, osstatus):
         return "Select failed: \(id) / \(osstatus)"
      case .getCurrentFailed:
         return "Get current failed."
      case let .getPreviousFailed(id):
         return "Get previous failed: \(id)"
      case .previousIDNotFound:
         return "Previous ID not found."
      case let .createDirFailed(dir):
         return "Create dir failed: \(dir)"
      case let .saveFailed(path):
         return "Save failed to: \(path)"
      case let .loadFailed(path):
         return "Load failed from: \(path)"
      case let .jsonSerializationFailed(msg):
         return "Json serializention failed: \(msg)"
      case let .invalidSubCommand(subcmd):
         return "Invalid sub command: \(subcmd)"
      case .missingTargetID:
         return "Target IME ID is missing."
      }
   }
}
