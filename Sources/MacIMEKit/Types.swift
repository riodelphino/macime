import Foundation

public enum Defaults {
   public static let version: String = "4.1.3"

   public static func macimePath() throws -> String {
      let env = ProcessInfo.processInfo.environment
      let checkPaths = [env["MACIME_PATH"], "/usr/local/bin/macime", "/opt/homebrew/bin/macime"]
      let path = Util.fallbackPaths(checkPathExists: true, paths: checkPaths)
      guard let path else {
         throw AppError.config(.invalidMacimePath)
      }
      return path
   }

   public static func sockPath() throws -> String {
      let env = ProcessInfo.processInfo.environment
      let checkPaths = [env["MACIME_SOCK_PATH"], "/tmp/riodelphino.macimed.sock"]
      let path = Util.fallbackPaths(checkPathExists: false, paths: checkPaths)
      guard let path else {
         throw AppError.config(.invalidSockPath)
      }
      return path
   }

   public static func tempDir() throws -> String {
      let env = ProcessInfo.processInfo.environment
      let checkPaths = [env["MACIME_TEMP_DIR"], "/tmp/riodelphino.macime"]
      let path = Util.fallbackPaths(checkPathExists: false, paths: checkPaths)
      guard let path else {
         throw AppError.config(.invalidTempDir)
      }
      return path
   }
}

/// [macime] Keep commmand line args
public struct IMECmdState {
   public var subcmd: String?
   public var save: Bool = false
   public var newID: String?
   public var selectCapable: Bool = false
   public var detail: Bool = false
   public var sessionID: String?
   public var cjkRefresh: Bool = false
   public init() {}
}

/// [macimed] Keep command line args
public struct IMEDCmdState {
   public var macimePath: String?
   public var sockPath: String?
   public var status: String?
   public var logPath: String?
   public var errPath: String?
   public init() throws {
      macimePath = try Defaults.macimePath()
      sockPath = try Defaults.sockPath()
      status = try IMED.isMacimedRunning(sockPath: Defaults.sockPath()) ? "running" : "stopped"
   }
}

public struct IMEDCommand {
   public let method: String?
   public let args: [String]?
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
