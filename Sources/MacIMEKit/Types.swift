import Foundation

public enum Defaults {
   public static let version: String = "3.5.0"

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
   public var cjkRefresh: Bool = false
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
