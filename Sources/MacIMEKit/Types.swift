import Foundation

/// [Common] Default values
public enum Defaults {
   public static let version: String = "4.5.0"

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

/// [Common] Runtime options
public enum Runtime {
   public static var logLevel: LogLevel = .info
}

/// [Common] Color
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

/// [IME] Sub commands
public enum IMESubCmd: String {
   case get
   case set
   case load
   case save
   case list

   var validOptions: Set<IMEOption> {
      switch self {
      case .get:
         return [.detail, .launchd, .debug]
      case .set:
         return [.save, .sessionID, .cjkRefresh, .cjkDelay, .launchd, .debug]
      case .load:
         return [.sessionID, .cjkRefresh, .cjkDelay, .launchd, .debug]
      case .save:
         return [.sessionID, .launchd, .debug]
      case .list:
         return [.selectCapable, .detail, .launchd, .debug]
      }
   }

   public init(_ rawValue: String) throws {
      guard let subcmd = IMESubCmd(rawValue: rawValue) else {
         throw AppError.cmd(.invalidSubCommand(rawValue))
      }
      self = subcmd
   }
}

/// [IME] Options
public enum IMEOption: String {
   case save = "--save"
   case sessionID = "--session-id"
   case selectCapable = "--select-capable"
   case detail = "--detail"
   case cjkRefresh = "--cjk-refresh"
   case cjkDelay = "--cjk-delay"
   case launchd = "--launchd" // TODO: [Backward compatibility] REMOVE in later version
   case debug = "--debug"

   public init(_ rawValue: String) throws {
      guard let opt = IMEOption(rawValue: rawValue) else {
         throw AppError.cmd(.invalidOption(rawValue))
      }
      self = opt
   }
}

/// [IME] State
public struct IMEState {
   public var subcmd: IMESubCmd?
   public var newID: String?
   public var save: Bool = false
   public var sessionID: String?
   public var selectCapable: Bool = false
   public var detail: Bool = false
   public var cjkRefresh: Bool = false
   public var cjkDelay: Double?
   public var launchd: Bool = false // TODO: [Backward compatibility] REMOVE in later version
   public var debug: Bool = false
   public init() {}
}

/// [IME] Output formats
public enum OutFormat {
   case text
   case json
}

/// [IME] Field
public enum IMEField: String {
   case id
   case localizedName
   case isSelectCapable
   case isSelected
   case sourceLanguages
}

/// [IME] Field list
public enum IMEFieldList {
   case id
   case detail
   var fields: [IMEField] {
      switch self {
      case .id:
         return [.id]
      case .detail:
         return [.id, .localizedName, .isSelectCapable, .isSelected, .sourceLanguages]
      }
   }
}

/// [IMED] State
public struct IMEDState {
   public var sockPath: String?
   public var status: String?
   public var logPath: String?
   public var errPath: String?
   public var debug: Bool = false
   public init() throws {
      sockPath = try Defaults.sockPath()
      status = try IMED.isMacimedRunning(sockPath: Defaults.sockPath()) ? "running" : "stopped"
   }
}

/// [IMED] Method
public enum IMEDMethod: String {
   case ime
   case daemon

   public init(_ rawValue: String) throws {
      guard let method = IMEDMethod(rawValue: rawValue) else {
         throw AppError.imed(.invalidDaemonMethod(rawValue))
      }
      self = method
   }
}

/// [IMED] Sub command
public enum IMEDSubCmd: String {
   case info
   case get
   case set

   public init(_ rawValue: String) throws {
      guard let subcmd = IMEDSubCmd(rawValue: rawValue) else {
         throw AppError.imed(.invalidDaemonSubcmd(rawValue))
      }
      self = subcmd
   }
}

/// [IMED] Log level
public enum LogLevel: Int, Comparable {
   case debug = 0
   case info
   case warn
   case error

   public init?(_ level: String) {
      switch level.lowercased() {
      case "debug": self = .debug
      case "info": self = .info
      case "warn": self = .warn
      case "error": self = .error
      default: return nil
      }
   }

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

   public var string: String {
      switch self {
      case .debug: return "debug"
      case .info: return "info"
      case .warn: return "warn"
      case .error: return "error"
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

   public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
      return lhs.rawValue < rhs.rawValue
   }
}

/// [IMED] Result
public enum IMEDResult {
   case success(String)
   case failure(String)
   public init(stdout: String, stderr: String) {
      if stderr.isEmpty {
         let stdout = stdout.trimmingCharacters(in: .newlines)
         self = .success(stdout)
      } else {
         let stderr = stderr.trimmingCharacters(in: .newlines)
         self = .failure(stderr)
      }
   }
}
