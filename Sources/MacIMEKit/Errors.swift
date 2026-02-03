import Foundation

public enum AppError: Error {
   case config(ConfigError)
   case cmd(CmdError)
   case util(UtilError)
   case ime(IMEError)
   case imed(IMEDError)

   public var message: String {
      switch self {
      case .config(let e):
         return e.message
      case .cmd(let e):
         return e.message
      case .util(let e):
         return e.message
      case .ime(let e):
         return e.message
      case .imed(let e):
         return e.message
      }
   }
}

public enum ConfigError: Error {  // TODO: Remove if unused
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
      case .invalidSubCommand(let subcmd):
         return "Invalid sub command: \(subcmd)"
      case .missingSessionID:
         return "`--session-id` option requires session ID."
      case .invalidOption(let option):
         return "Unknown option: \(option)"
      case .subcmdNotFound:
         return "Sub command not found."
      case .unknownOptionForSubcmd(let subcmd, let option):
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
   case macimeReturnsError(String)

   public var message: String {
      switch self {
      case .macimeNotFound(let path):
         return "macime executable not found: \(path)"
      case .dataNotRecieved:
         return "Data not recieved."
      case .macimeReturnsError(let err):
         return "`macime` returns Error: \(err)"
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
