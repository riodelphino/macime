import Foundation

public enum Defaults {
   public static let version: String = "4.1.4"

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

/// [Common] Keep runtime options
public enum Runtime {
   public static var logLevel: LogLevel = .info
}

/// [macime] Commmand line args
public struct IMEState {
   public var subcmd: String?
   public var save: Bool = false
   public var newID: String?
   public var selectCapable: Bool = false
   public var detail: Bool = false
   public var sessionID: String?
   public var cjkRefresh: Bool = false
   public var debug: Bool = false
   public init() {}
}

/// [macime] Output formats
public enum OutFormat {
   case text
   case json
}

/// [macimed] Keep command line args
public struct IMEDState {
   public var macimePath: String?
   public var sockPath: String?
   public var status: String?
   public var logPath: String?
   public var errPath: String?
   public var debug: Bool = false
   public init() throws {
      macimePath = try Defaults.macimePath()
      sockPath = try Defaults.sockPath()
      status = try IMED.isMacimedRunning(sockPath: Defaults.sockPath()) ? "running" : "stopped"
   }
}

public enum LogLevel: Int {
   case debug = 0
   case info
   case warn
   case error

   public var desc: String {
      switch self {
      case .debug:
         return "DEBUG"
      case .info:
         return " INFO"
      case .warn:
         return " WARN"
      case .error:
         return "ERROR"
      }
   }

   public var color: Color {
      switch self {
      case .debug:
         return Color.gray
      case .info:
         return Color.green
      case .warn:
         return Color.yellow
      case .error:
         return Color.red
      }
   }
}

extension LogLevel: Comparable {
   public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
      return lhs.rawValue < rhs.rawValue
   }
}

public enum Color {
   case normal
   case gray
   case red
   case blue
   case green
   case yellow
   case reset

   public var seq: String {
      switch self {
      case .normal:
         return ""
      case .gray:
         return "\u{001B}[90m"
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

   public func colorize(_ text: String) -> String {
      if self == .normal {
         return text
      } else {
         return "\(seq)\(text)\(Color.reset.seq)"
      }
   }
}
